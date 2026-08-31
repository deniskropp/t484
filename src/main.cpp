#include "ocsnode/qt/KlmxMoleculeItem.h"
#include "ocsnode/qt/ProtocolEngineQt.h"
#include "ocsnode/qt/TasStatusModel.h"

#include <QFile>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

static QString loadSeed()
{
    const QStringList candidates = {
        QStringLiteral(":/qt/qml/OcsNode/seed.ocs"),
        QStringLiteral("src/assets/seed.ocs"),
        QStringLiteral("../src/assets/seed.ocs"),
    };
    for (const auto &path : candidates) {
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

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName(QStringLiteral("Exit"));
    app.setApplicationName(QStringLiteral("t484"));
    app.setApplicationDisplayName(QStringLiteral("OCS/Node Engine"));

    ocsnode::ProtocolEngineQt engine;
    ocsnode::TasStatusModel tasModel;
    ocsnode::KlmxMoleculeItem klmxItem;

    engine.setActor(QStringLiteral("KickFlow"));
    engine.loadText(loadSeed());

    if (const auto body = engine.sectionBody(QStringLiteral("context/klmx")); !body.isEmpty())
        klmxItem.setFormula(body);

    QQmlApplicationEngine qml;
    auto *ctx = qml.rootContext();
    ctx->setContextProperty(QStringLiteral("engine"), &engine);
    ctx->setContextProperty(QStringLiteral("tasModel"), &tasModel);
    ctx->setContextProperty(QStringLiteral("klmxItem"), &klmxItem);

    const QUrl url(QStringLiteral("qrc:/qt/qml/OcsNode/main.qml"));
    QObject::connect(
        &qml, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    qml.load(url);

    return app.exec();
}
