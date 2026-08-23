#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setOrganizationName("Exit");
    app.setApplicationName("t484");
    app.setApplicationDisplayName("OCS/Node Engine");

    QQmlApplicationEngine engine;

    // Expose future C++ protocol handler here
    // engine.rootContext()->setContextProperty("protocolEngine", &handler);

    const QUrl url(u"qrc:/qt/qml/OcsNode/main.qml"_qs);
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
