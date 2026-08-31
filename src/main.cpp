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

static QUrl mainQmlUrl()
{
    const QString path = firstExisting({
        QStringLiteral(":/qt/qml/OcsNode/main.qml"),
        QStringLiteral(":/OcsNode/src/qml/main.qml"),
        QStringLiteral(":/OcsNode/main.qml"),
    });
    if (!path.isEmpty())
        return QUrl(QStringLiteral("qrc") + path);
    return QUrl(QStringLiteral("qrc:/qt/qml/OcsNode/main.qml"));
}

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("Exit"));
    app.setApplicationName(QStringLiteral("t484"));
    app.setApplicationDisplayName(QStringLiteral("OCS/Node Chat"));

    ocsnode::ProtocolEngineQt engine;
    ocsnode::TasStatusModel tasModel;
    ocsnode::KlmxMoleculeItem klmxItem;

    engine.setActor(QStringLiteral("KickFlow"));
    std::fprintf(stderr, "t484: genai ready=%s source=%s model=%s\n",
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
    engine.loadText(loadSeed());

    if (const auto body = engine.sectionBody(QStringLiteral("context/klmx")); !body.isEmpty())
        klmxItem.setFormula(body);

    QQmlApplicationEngine qml;
    auto *ctx = qml.rootContext();
    ctx->setContextProperty(QStringLiteral("engine"), &engine);
    ctx->setContextProperty(QStringLiteral("tasModel"), &tasModel);
    ctx->setContextProperty(QStringLiteral("klmxItem"), &klmxItem);

    const QUrl url = mainQmlUrl();
    QObject::connect(
        &qml, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    qml.load(url);

    return app.exec();
}
