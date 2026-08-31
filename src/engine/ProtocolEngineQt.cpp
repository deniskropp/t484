#include "ocsnode/qt/ProtocolEngineQt.h"
#include "ocsnode/ChatSession.h"

namespace ocsnode {
namespace {

constexpr int kMaxContextChars = 24000;

const char *kSystemInstruction =
    "You are KickFlow in t484 OCS/Node Engine (OCS v2.1). "
    "Three-agent-core: KickForge extracts TAS/objectives, KickFlow executes, "
    "KickGuard owns consent and halt. "
    "The chat transcript is a living KickLang protocol document using ⫻ sections "
    "(protocol/ocs, cmd/*, data/obj, data/tas, flow/chat, query/clarify, display/*). "
    "Reply in clear prose to the host. When you propose protocol, emit ⫻ sigil blocks. "
    "Do not claim external side effects you did not perform. "
    "If the host asks to halt, remind them /halt is a first-class local command.";

Section makeQtSection(const QString &family, const QString &path,
                      const QString &qualifier, const QString &body)
{
    Section s;
    s.family = family.toStdString();
    s.path = path.toStdString();
    s.qualifier = qualifier.toStdString();
    s.body = body.toStdString();
    return s;
}

} // namespace

ProtocolEngineQt::ProtocolEngineQt(QObject *parent)
    : QObject(parent)
{
    m_node.protocol().setHaltHandler([this](const std::string &reason) {
        m_genai.abort();
        emit haltRequested(QString::fromStdString(reason));
        emit busyChanged();
    });
    connect(&m_genai, &GenAiClient::finished, this, &ProtocolEngineQt::onGenAiFinished);
    connect(&m_genai, &GenAiClient::busyChanged, this, &ProtocolEngineQt::busyChanged);
    emit genaiReadyChanged();
}

QString ProtocolEngineQt::mode() const
{
    return QString::fromStdString(m_node.protocol().state().mode);
}

void ProtocolEngineQt::setMode(const QString &mode)
{
    if (this->mode() == mode)
        return;
    m_node.protocol().setMode(mode.toStdString());
    syncFromCore();
    emit modeChanged();
}

QString ProtocolEngineQt::status() const
{
    return QString::fromStdString(m_node.protocol().state().status);
}

double ProtocolEngineQt::coherence() const
{
    return m_node.protocol().state().coherence;
}

bool ProtocolEngineQt::gated() const
{
    return m_node.protocol().state().gated;
}

QString ProtocolEngineQt::haltReason() const
{
    return QString::fromStdString(m_node.protocol().state().haltReason);
}

QString ProtocolEngineQt::currentTasId() const
{
    return QString::fromStdString(m_node.protocol().state().currentTasId);
}

int ProtocolEngineQt::activeSteps() const
{
    return m_node.protocol().state().activeSteps;
}

QString ProtocolEngineQt::actor() const
{
    return QString::fromStdString(m_node.actor());
}

void ProtocolEngineQt::setActor(const QString &actor)
{
    if (this->actor() == actor)
        return;
    m_node.setActor(actor.toStdString());
    emit actorChanged();
}

QString ProtocolEngineQt::sourceText() const
{
    return m_source;
}

int ProtocolEngineQt::errorCount() const
{
    return int(m_node.protocol().errors().size());
}

bool ProtocolEngineQt::busy() const
{
    return m_genai.busy();
}

bool ProtocolEngineQt::genaiReady() const
{
    return m_genai.ready();
}

QString ProtocolEngineQt::genaiModel() const
{
    return m_genai.model();
}

QString ProtocolEngineQt::genaiSource() const
{
    return m_genai.apiKeySource();
}

bool ProtocolEngineQt::loadText(const QString &text)
{
    m_source = text;
    auto result = m_node.ingest(text.toStdString());
    syncFromCore();
    emit sourceChanged();
    return result.ok();
}

QString ProtocolEngineQt::emitText() const
{
    return QString::fromStdString(m_node.protocol().emitText());
}

void ProtocolEngineQt::requestHalt(const QString &reason)
{
    m_genai.abort();
    m_node.protocol().requestHalt(reason.toStdString());
    syncFromCore();
    emit busyChanged();
}

void ProtocolEngineQt::submitMap(const QVariantMap &payload)
{
    Section s;
    const auto type = payload.value(QStringLiteral("sectionType")).toString();
    const auto slash = type.indexOf('/');
    if (slash < 0) {
        s.family = type.toStdString();
    } else {
        s.family = type.left(slash).toStdString();
        s.path = type.mid(slash + 1).toStdString();
    }
    s.qualifier = payload.value(QStringLiteral("qualifier")).toString().toStdString();
    if (s.qualifier.empty())
        s.qualifier = payload.value(QStringLiteral("molecule")).toString().toStdString();
    s.body = payload.value(QStringLiteral("body")).toString().toStdString();
    if (s.body.empty())
        s.body = payload.value(QStringLiteral("formula")).toString().toStdString();
    m_node.protocol().submit(s);
    syncFromCore();
    emit accepted(payload);
}

QString ProtocolEngineQt::sectionBody(const QString &type) const
{
    if (const auto *s = m_node.protocol().findByType(type.toStdString()))
        return QString::fromStdString(s->body);
    return {};
}

bool ProtocolEngineQt::sendChat(const QString &text)
{
    ChatSession session(m_node.protocol());
    const auto result = session.send(text.toStdString());
    syncFromCore();
    emit turnCompleted(result.ok);
    if (result.requestLlm && result.ok && !result.gated)
        requestGenAi(text);
    return result.ok;
}

void ProtocolEngineQt::appendChat(const QString &qualifier, const QString &body)
{
    m_node.protocol().append(makeQtSection(QStringLiteral("flow"), QStringLiteral("chat"),
                                           qualifier, body));
    syncFromCore();
}

void ProtocolEngineQt::requestGenAi(const QString &hostText)
{
    if (gated()) {
        appendChat(QStringLiteral("KickGuard"),
                   QStringLiteral("KickGuard blocked genai: node is gated."));
        return;
    }
    if (!m_genai.ready()) {
        m_node.protocol().append(makeQtSection(
            QStringLiteral("query"), QStringLiteral("clarify"), QStringLiteral("genai"),
            QStringLiteral("KickGuard: no Gemini key in this process. "
                           "This GUI does not inherit your interactive shell. "
                           "Export GEMINI_API_KEY (or GOOGLE_API_KEY / GOOGLE_AI_API_KEY) "
                           "in the launch environment, or put it in .env next to the binary "
                           "or in ~/.config/t484/.env, then restart t484. "
                           "The key is never written into the protocol document.")));
        syncFromCore();
        return;
    }

    QString snapshot = QString::fromStdString(m_node.protocol().emitText());
    if (snapshot.size() > kMaxContextChars)
        snapshot = snapshot.right(kMaxContextChars);

    m_node.protocol().append(makeQtSection(
        QStringLiteral("cmd"), QStringLiteral("exec"), QStringLiteral("genai"),
        QStringLiteral("model=") + m_genai.model()));

    appendChat(QStringLiteral("KickFlow"),
               QStringLiteral("KickFlow · calling Google GenAI Interactions (")
                   + m_genai.model() + QStringLiteral(")…"));

    const QString input = QStringLiteral("Living protocol document:\n") + snapshot
        + QStringLiteral("\n\nHost turn:\n") + hostText.trimmed();

    m_node.setActor("KickFlow");
    emit actorChanged();
    m_genai.create(input, QString::fromUtf8(kSystemInstruction), m_previousInteractionId);
}

void ProtocolEngineQt::onGenAiFinished(bool ok, const QString &text,
                                      const QString &interactionId, const QString &error,
                                      const QString &usedModel)
{
    if (!interactionId.isEmpty())
        m_previousInteractionId = interactionId;

    if (gated()) {
        appendChat(QStringLiteral("KickGuard"),
                   QStringLiteral("KickGuard dropped genai output: halt gate closed while waiting."));
        return;
    }

    if (!ok) {
        m_node.protocol().append(makeQtSection(
            QStringLiteral("query"), QStringLiteral("clarify"), QStringLiteral("genai"),
            QStringLiteral("KickFlow: Google GenAI error.\n") + error));
        syncFromCore();
        return;
    }

    QString body = text;
    if (!usedModel.isEmpty() && usedModel != m_genai.model())
        body += QStringLiteral("\n\n— ") + usedModel
            + QStringLiteral(" (fallback from ") + m_genai.model() + QStringLiteral(")");
    appendChat(QStringLiteral("KickFlow"), body);
}

void ProtocolEngineQt::syncFromCore()
{
    m_model.resetFrom(m_node.protocol().sections());
    m_source = QString::fromStdString(m_node.protocol().emitText());
    emit stateChanged();
    emit modeChanged();
    emit sourceChanged();
}

} // namespace ocsnode
