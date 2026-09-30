#include "ocsnode/qt/EventLogModel.h"
#include "ocsnode/qt/GenAiClient.h"
#include "ocsnode/qt/KlmxMoleculeItem.h"
#include "ocsnode/qt/ProtocolEngineQt.h"
#include "ocsnode/qt/TasStatusModel.h"

#include <QFile>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QUrl>
#include <cstdio>

static QString firstExisting(const QStringList &candidates)
{
    for (const auto &path : candidates) {
        if (QFile::exists(path))
            return path;
    }
    return {};
}

static QString loadSeed()
{
    const QString path = firstExisting({
        QStringLiteral(":/qt/qml/OcsNode/seed.ocs"),
        QStringLiteral(":/OcsNode/src/assets/seed.ocs"),
        QStringLiteral("src/assets/seed.ocs"),
        QStringLiteral("../src/assets/seed.ocs"),
    });
    if (!path.isEmpty()) {
        QFile f(path);
        if (f.open(QIODevice::ReadOnly))
            return QString::fromUtf8(f.readAll());
    }
    return QString::fromUtf8(
        "\xE2\xAB\xBB"
        "protocol/ocs: [node=OCS/Root]\n"
        "\xE2\xAB\xBB"
        "context/klmx:Kick/Lang\nfallback seed\n");
}

// Flag precedence: --kirigami > --console > --chat > compile default.
static QString selectedShell(const QStringList &args)
{
#ifdef T484_SHELL_KIRIGAMI
    QString def = QStringLiteral("kirigami");
#elif defined(T484_SHELL_CONSOLE)
    QString def = QStringLiteral("console");
#else
    QString def = QStringLiteral("chat");
#endif
    if (args.contains(QStringLiteral("--kirigami")))
        return QStringLiteral("kirigami");
    if (args.contains(QStringLiteral("--console")))
        return QStringLiteral("console");
    if (args.contains(QStringLiteral("--chat")))
        return QStringLiteral("chat");
    return def;
}

static QString qmlFileForShell(const QString &shell)
{
    if (shell == QLatin1String("kirigami"))
        return QStringLiteral("kirigami.qml");
    if (shell == QLatin1String("console"))
        return QStringLiteral("console.qml");
    return QStringLiteral("main.qml");
}

static QUrl mainQmlUrl(const QString &shell)
{
    const QString name = qmlFileForShell(shell);
    const QString path = firstExisting({
        QStringLiteral(":/qt/qml/OcsNode/") + name,
        QStringLiteral(":/OcsNode/src/qml/") + name,
        QStringLiteral(":/OcsNode/") + name,
    });
    if (!path.isEmpty())
        return QUrl(QStringLiteral("qrc") + path);
    return QUrl(QStringLiteral("qrc:/qt/qml/OcsNode/") + name);
}

static const char *displayNameForShell(const QString &shell)
{
    if (shell == QLatin1String("kirigami"))
        return "t484 Kirigami";
    if (shell == QLatin1String("console"))
        return "t484 Protocol Console";
    return "OCS/Node Chat";
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("Exit"));
    app.setApplicationName(QStringLiteral("t484"));

    const QString shell = selectedShell(app.arguments());
    app.setApplicationDisplayName(QString::fromUtf8(displayNameForShell(shell)));

    ocsnode::ProtocolEngineQt engine;
    ocsnode::TasStatusModel tasModel;
    ocsnode::KlmxMoleculeItem klmxItem;
    ocsnode::EventLogModel eventLogModel;

    engine.setActor(QStringLiteral("KickFlow"));
    std::fprintf(stderr, "t484: shell=%s genai ready=%s source=%s model=%s\n",
                 qPrintable(shell),
                 engine.genaiReady() ? "yes" : "no",
                 qPrintable(engine.genaiSource().isEmpty()
                                ? QStringLiteral("(none)")
                                : engine.genaiSource()),
                 qPrintable(engine.genaiModel()));
    if (app.arguments().contains(QStringLiteral("--genai-debug"))) {
        std::fprintf(stderr, "%s\n", qPrintable(ocsnode::GenAiClient::debugReport()));
        return engine.genaiReady() ? 0 : 1;
    }
    if (app.arguments().contains(QStringLiteral("--genai-status")))
        return engine.genaiReady() ? 0 : 1;

    QObject::connect(&engine, &ocsnode::ProtocolEngineQt::turnCompleted,
                     &eventLogModel, [&eventLogModel](bool ok) {
        eventLogModel.appendEvent(ok ? QStringLiteral("info") : QStringLiteral("error"),
                                  QStringLiteral("turnCompleted"),
                                  ok ? QStringLiteral("ok") : QStringLiteral("failed"));
    });
    QObject::connect(&engine, &ocsnode::ProtocolEngineQt::stateChanged,
                     &eventLogModel, [&engine, &eventLogModel]() {
        eventLogModel.appendEvent(QStringLiteral("protocol"),
                                  QStringLiteral("state"),
                                  engine.status()
                                      + QStringLiteral(" gated=")
                                      + (engine.gated() ? QStringLiteral("true")
                                                        : QStringLiteral("false"))
                                      + QStringLiteral(" errors=")
                                      + QString::number(engine.errorCount()));
    });
    QObject::connect(&engine, &ocsnode::ProtocolEngineQt::haltRequested,
                     &eventLogModel, [&eventLogModel](const QString &reason) {
        eventLogModel.appendEvent(QStringLiteral("warning"),
                                  QStringLiteral("halt"),
                                  reason);
    });
    QObject::connect(&engine, &ocsnode::ProtocolEngineQt::busyChanged,
                     &eventLogModel, [&engine, &eventLogModel]() {
        eventLogModel.appendEvent(QStringLiteral("genai"),
                                  QStringLiteral("busy"),
                                  engine.busy() ? QStringLiteral("start")
                                                : QStringLiteral("end"));
    });

    eventLogModel.appendEvent(QStringLiteral("info"),
                              QStringLiteral("boot"),
                              QString::fromUtf8(displayNameForShell(shell)));
    eventLogModel.appendEvent(QStringLiteral("genai"),
                              QStringLiteral("source"),
                              engine.genaiReady() ? engine.genaiSource()
                                                  : QStringLiteral("NO KEY"));

    engine.loadText(loadSeed());

    if (const auto body = engine.sectionBody(QStringLiteral("context/klmx")); !body.isEmpty())
        klmxItem.setFormula(body);

    QQmlApplicationEngine qml;
    auto *ctx = qml.rootContext();
    ctx->setContextProperty(QStringLiteral("engine"), &engine);
    ctx->setContextProperty(QStringLiteral("tasModel"), &tasModel);
    ctx->setContextProperty(QStringLiteral("klmxItem"), &klmxItem);
    ctx->setContextProperty(QStringLiteral("eventLogModel"), &eventLogModel);

    const QUrl url = mainQmlUrl(shell);
    QObject::connect(
        &qml, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    qml.load(url);

    return app.exec();
}
