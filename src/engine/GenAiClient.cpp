#include "ocsnode/qt/GenAiClient.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkRequest>
#include <QSet>
#include <QStandardPaths>
#include <QStringList>
#include <QUrl>

namespace ocsnode {
namespace {

const QStringList kKeyNames = {
    QStringLiteral("GEMINI_API_KEY"),
    QStringLiteral("GOOGLE_API_KEY"),
    QStringLiteral("GOOGLE_GENAI_API_KEY"),
    QStringLiteral("GOOGLE_AI_API_KEY"),
};

QString unquote(QString v)
{
    v = v.trimmed();
    if (v.size() >= 2) {
        const QChar a = v.front();
        const QChar b = v.back();
        if ((a == '"' && b == '"') || (a == '\'' && b == '\''))
            return v.mid(1, v.size() - 2);
    }
    return v;
}

QString getenvTrimmed(const QString &name)
{
    return unquote(QString::fromUtf8(qgetenv(name.toUtf8().constData())));
}

struct ResolvedKey {
    QString value;
    QString source;
};

void appendWalk(QStringList &out, QString start)
{
    QDir d(start);
    if (start.isEmpty() || !d.exists())
        return;
    for (int i = 0; i < 10; ++i) {
        out << d.filePath(QStringLiteral(".env"));
        out << d.filePath(QStringLiteral(".env.local"));
        const QString here = d.absolutePath();
        if (here == QDir::homePath() || here == QDir::rootPath())
            break;
        if (!d.cdUp())
            break;
    }
}

QStringList keyFileCandidates()
{
    QStringList out;
#ifdef T484_SOURCE_DIR
    {
        const QDir src(QStringLiteral(T484_SOURCE_DIR));
        out << src.filePath(QStringLiteral(".env"));
        out << src.filePath(QStringLiteral(".env.local"));
    }
#endif
    appendWalk(out, QDir::currentPath());
    appendWalk(out, QCoreApplication::applicationDirPath());

    const QString cfg = QStandardPaths::writableLocation(QStandardPaths::AppConfigLocation);
    if (!cfg.isEmpty())
        out << QDir(cfg).filePath(QStringLiteral(".env"));
    out << QDir::home().filePath(QStringLiteral(".config/t484/.env"));
    out << QDir::home().filePath(QStringLiteral(".config/Exit/t484/.env"));

    const QString runtime = getenvTrimmed(QStringLiteral("XDG_RUNTIME_DIR"));
    if (!runtime.isEmpty()) {
        out << QDir(runtime).filePath(QStringLiteral("t484.env"));
        out << QDir(runtime).filePath(QStringLiteral("ocs-qml6/llm.env"));
    }

    QStringList unique;
    QSet<QString> seen;
    for (const auto &p : out) {
        const auto clean = QDir::cleanPath(p);
        if (seen.contains(clean))
            continue;
        seen.insert(clean);
        unique << clean;
    }
    return unique;
}

ResolvedKey resolveApiKey()
{
    for (const auto &name : kKeyNames) {
        const auto v = getenvTrimmed(name);
        if (!v.isEmpty())
            return {v, QStringLiteral("env:") + name};
    }

    for (const auto &path : keyFileCandidates()) {
        QFile f(QDir::cleanPath(path));
        if (!f.open(QIODevice::ReadOnly))
            continue;
        const auto map = GenAiClient::parseDotEnv(f.readAll());
        for (const auto &name : kKeyNames) {
            const auto v = map.value(name).trimmed();
            if (v.isEmpty())
                continue;
            return {v, QStringLiteral("file:") + QDir::cleanPath(path)};
        }
    }
    return {};
}

QString envFirst(const QStringList &names)
{
    for (const auto &name : names) {
        const auto v = getenvTrimmed(name);
        if (!v.isEmpty())
            return v;
    }
    return {};
}

QString jsonErrorMessage(const QJsonObject &root)
{
    const auto err = root.value(QStringLiteral("error"));
    if (err.isObject()) {
        const auto msg = err.toObject().value(QStringLiteral("message")).toString();
        if (!msg.isEmpty())
            return msg;
    } else if (err.isString()) {
        return err.toString();
    }
    return {};
}

QString collectModelText(const QJsonObject &root)
{
    QString text;
    const auto steps = root.value(QStringLiteral("steps")).toArray();
    for (const auto &stepVal : steps) {
        const auto step = stepVal.toObject();
        if (step.value(QStringLiteral("type")).toString() != QLatin1String("model_output"))
            continue;
        const auto content = step.value(QStringLiteral("content")).toArray();
        for (const auto &cVal : content) {
            const auto c = cVal.toObject();
            if (c.value(QStringLiteral("type")).toString() == QLatin1String("text")) {
                if (!text.isEmpty())
                    text += QLatin1Char('\n');
                text += c.value(QStringLiteral("text")).toString();
            }
        }
    }
    if (text.isEmpty())
        text = root.value(QStringLiteral("output_text")).toString();
    if (text.isEmpty()) {
        const auto outputs = root.value(QStringLiteral("outputs")).toArray();
        for (const auto &oVal : outputs) {
            const auto o = oVal.toObject();
            if (o.value(QStringLiteral("type")).toString() == QLatin1String("text")) {
                if (!text.isEmpty())
                    text += QLatin1Char('\n');
                text += o.value(QStringLiteral("text")).toString();
            }
        }
    }
    return text.trimmed();
}

} // namespace

GenAiClient::GenAiClient(QObject *parent)
    : QObject(parent)
{
    const auto resolved = resolveApiKey();
    if (!resolved.value.isEmpty() && getenvTrimmed(QStringLiteral("GEMINI_API_KEY")).isEmpty())
        qputenv("GEMINI_API_KEY", resolved.value.toUtf8());
}

QHash<QString, QString> GenAiClient::parseDotEnv(const QByteArray &raw)
{
    QHash<QString, QString> out;
    QByteArray text = raw;
    if (text.startsWith("\xEF\xBB\xBF"))
        text = text.mid(3);
    const auto lines = QString::fromUtf8(text).split(QLatin1Char('\n'));
    for (QString line : lines) {
        if (!line.isEmpty() && line.back() == QLatin1Char('\r'))
            line.chop(1);
        line = line.trimmed();
        if (line.isEmpty() || line.startsWith(QLatin1Char('#')))
            continue;
        if (line.startsWith(QLatin1String("export ")))
            line = line.mid(7).trimmed();
        int sep = line.indexOf(QLatin1Char('='));
        if (sep < 0)
            sep = line.indexOf(QLatin1Char(':'));
        if (sep <= 0)
            continue;
        const auto key = line.left(sep).trimmed();
        const auto value = unquote(line.mid(sep + 1));
        if (!key.isEmpty())
            out.insert(key, value);
    }
    return out;
}

QString GenAiClient::apiKey() const
{
    return resolveApiKey().value;
}

QString GenAiClient::apiKeySource() const
{
    const auto r = resolveApiKey();
    return r.value.isEmpty() ? QString() : r.source;
}

QString GenAiClient::debugReport()
{
    QStringList lines;
    for (const auto &name : kKeyNames) {
        const auto v = getenvTrimmed(name);
        lines << (v.isEmpty()
                      ? QStringLiteral("env  MISS  %1").arg(name)
                      : QStringLiteral("env  HIT   %1  len=%2").arg(name).arg(v.size()));
    }
    const auto files = keyFileCandidates();
    lines << QStringLiteral("cwd  %1").arg(QDir::currentPath());
    lines << QStringLiteral("app  %1").arg(QCoreApplication::applicationDirPath());
#ifdef T484_SOURCE_DIR
    lines << QStringLiteral("src  %1").arg(QStringLiteral(T484_SOURCE_DIR));
#endif
    for (const auto &path : files) {
        QFile f(path);
        if (!f.exists()) {
            lines << QStringLiteral("file MISS  %1").arg(path);
            continue;
        }
        if (!f.open(QIODevice::ReadOnly)) {
            lines << QStringLiteral("file OPEN  %1").arg(path);
            continue;
        }
        const auto map = parseDotEnv(f.readAll());
        QStringList hit;
        for (const auto &name : kKeyNames) {
            const auto v = map.value(name);
            if (!v.isEmpty())
                hit << QStringLiteral("%1 len=%2").arg(name).arg(v.size());
        }
        lines << (hit.isEmpty()
                      ? QStringLiteral("file EMPTY %1  (no GEMINI/GOOGLE_*_API_KEY)").arg(path)
                      : QStringLiteral("file HIT   %1  %2").arg(path, hit.join(QStringLiteral(", "))));
    }
    const auto r = resolveApiKey();
    lines << (r.value.isEmpty()
                  ? QStringLiteral("resolved NONE")
                  : QStringLiteral("resolved %1  len=%2").arg(r.source).arg(r.value.size()));
    return lines.join(QLatin1Char('\n'));
}

QString GenAiClient::model() const
{
    const auto m = envFirst({QStringLiteral("GEMINI_MODEL"), QStringLiteral("GOOGLE_GENAI_MODEL")});
    return m.isEmpty() ? QStringLiteral("gemini-3.7-flash") : m;
}

QStringList GenAiClient::modelChain() const
{
    QStringList chain;
    chain << model();
    const QStringList fallbacks = {
        QStringLiteral("gemini-3.6-flash"),
        QStringLiteral("gemini-3.5-flash"),
    };
    for (const auto &f : fallbacks) {
        if (!chain.contains(f))
            chain << f;
    }
    return chain;
}

QString GenAiClient::currentModel() const
{
    const auto chain = modelChain();
    if (m_attempt >= 0 && m_attempt < chain.size())
        return chain.at(m_attempt);
    return model();
}

void GenAiClient::abort()
{
    if (!m_reply)
        return;
    m_reply->disconnect(this);
    m_reply->abort();
    m_reply->deleteLater();
    m_reply = nullptr;
    emit busyChanged();
}

QString GenAiClient::extractOutputText(const QByteArray &json, QString *interactionId,
                                       QString *status, QString *errorMessage)
{
    QJsonParseError pe;
    const auto doc = QJsonDocument::fromJson(json, &pe);
    if (pe.error != QJsonParseError::NoError || !doc.isObject()) {
        if (errorMessage)
            *errorMessage = pe.error != QJsonParseError::NoError
                ? pe.errorString()
                : QStringLiteral("genai response is not a JSON object");
        return {};
    }
    const auto root = doc.object();
    if (interactionId)
        *interactionId = root.value(QStringLiteral("id")).toString();
    if (status)
        *status = root.value(QStringLiteral("status")).toString();
    const auto err = jsonErrorMessage(root);
    if (!err.isEmpty()) {
        if (errorMessage)
            *errorMessage = err;
        return {};
    }
    const auto st = root.value(QStringLiteral("status")).toString();
    if (st == QLatin1String("failed") || st == QLatin1String("cancelled")) {
        if (errorMessage)
            *errorMessage = QStringLiteral("interaction status: ") + st;
        return {};
    }
    const auto text = collectModelText(root);
    if (text.isEmpty() && errorMessage)
        *errorMessage = QStringLiteral("no model_output text in interaction");
    return text;
}

void GenAiClient::create(const QString &input, const QString &systemInstruction,
                         const QString &previousInteractionId)
{
    if (m_reply)
        abort();

    if (apiKey().isEmpty()) {
        emit finished(false, {}, {},
                      QStringLiteral("GEMINI_API_KEY is not set. Export it (or GOOGLE_API_KEY) and retry."),
                      model());
        return;
    }

    m_input = input;
    m_systemInstruction = systemInstruction;
    m_previousInteractionId = previousInteractionId;
    m_attempt = 0;
    postAttempt();
}

void GenAiClient::postAttempt()
{
    const auto key = apiKey();
    QUrl url(QStringLiteral("https://generativelanguage.googleapis.com/v1beta/interactions"));
    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    req.setRawHeader("x-goog-api-key", key.toUtf8());
    req.setRawHeader("Accept", "application/json");
    req.setRawHeader("Api-Revision", "2026-05-20");
    req.setTransferTimeout(120000);

    QJsonObject body;
    body.insert(QStringLiteral("model"), currentModel());
    body.insert(QStringLiteral("input"), m_input);
    if (!m_systemInstruction.isEmpty())
        body.insert(QStringLiteral("system_instruction"), m_systemInstruction);
    if (!m_previousInteractionId.isEmpty())
        body.insert(QStringLiteral("previous_interaction_id"), m_previousInteractionId);

    const bool wasBusy = m_reply != nullptr;
    m_reply = m_nam.post(req, QJsonDocument(body).toJson(QJsonDocument::Compact));
    if (!wasBusy)
        emit busyChanged();
    connect(m_reply, &QNetworkReply::finished, this, &GenAiClient::onReplyFinished);
}

void GenAiClient::onReplyFinished()
{
    auto *reply = m_reply;
    m_reply = nullptr;
    if (!reply) {
        emit busyChanged();
        emit finished(false, {}, {}, QStringLiteral("empty genai reply"), currentModel());
        return;
    }
    reply->deleteLater();

    const auto bytes = reply->readAll();
    const int http = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    QString id;
    QString status;
    QString err;
    const auto text = extractOutputText(bytes, &id, &status, &err);
    if (text.isEmpty()) {
        if (err.isEmpty())
            err = reply->errorString();
        const bool capacity = http >= 500
            || err.contains(QStringLiteral("high demand"), Qt::CaseInsensitive)
            || err.contains(QStringLiteral("UNAVAILABLE"), Qt::CaseInsensitive)
            || err.contains(QStringLiteral("overloaded"), Qt::CaseInsensitive);
        if (capacity && m_attempt + 1 < modelChain().size()) {
            ++m_attempt;
            postAttempt();
            return;
        }
        emit busyChanged();
        emit finished(false, {}, id, err, currentModel());
        return;
    }
    emit busyChanged();
    emit finished(true, text, id, {}, currentModel());
}

} // namespace ocsnode
