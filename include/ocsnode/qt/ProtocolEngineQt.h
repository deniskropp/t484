#pragma once

#include "ocsnode/NodeEngine.h"
#include "ocsnode/qt/GenAiClient.h"
#include "ocsnode/qt/SectionListModel.h"

#include <QObject>
#include <QString>
#include <QVariantList>

namespace ocsnode {

class ProtocolEngineQt : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(QString status READ status NOTIFY stateChanged)
    Q_PROPERTY(double coherence READ coherence NOTIFY stateChanged)
    Q_PROPERTY(bool gated READ gated NOTIFY stateChanged)
    Q_PROPERTY(QString haltReason READ haltReason NOTIFY stateChanged)
    Q_PROPERTY(QString currentTasId READ currentTasId NOTIFY stateChanged)
    Q_PROPERTY(int activeSteps READ activeSteps NOTIFY stateChanged)
    Q_PROPERTY(QString actor READ actor WRITE setActor NOTIFY actorChanged)
    Q_PROPERTY(QString sourceText READ sourceText NOTIFY sourceChanged)
    Q_PROPERTY(SectionListModel *sections READ sections CONSTANT)
    Q_PROPERTY(int errorCount READ errorCount NOTIFY stateChanged)
    Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)
    Q_PROPERTY(bool genaiReady READ genaiReady NOTIFY genaiReadyChanged)
    Q_PROPERTY(QString genaiModel READ genaiModel NOTIFY genaiReadyChanged)
    Q_PROPERTY(QString genaiSource READ genaiSource NOTIFY genaiReadyChanged)

public:
    explicit ProtocolEngineQt(QObject *parent = nullptr);

    QString mode() const;
    void setMode(const QString &mode);

    QString status() const;
    double coherence() const;
    bool gated() const;
    QString haltReason() const;
    QString currentTasId() const;
    int activeSteps() const;
    QString actor() const;
    void setActor(const QString &actor);
    QString sourceText() const;
    SectionListModel *sections() { return &m_model; }
    int errorCount() const;
    bool busy() const;
    bool genaiReady() const;
    QString genaiModel() const;
    QString genaiSource() const;

    Q_INVOKABLE bool loadText(const QString &text);
    Q_INVOKABLE QString emitText() const;
    Q_INVOKABLE QString exportNexus();
    Q_INVOKABLE bool importNexus(const QString &text);
    Q_INVOKABLE bool saveNexusToFile(const QString &path);
    Q_INVOKABLE bool loadNexusFromFile(const QString &path);
    Q_INVOKABLE void requestHalt(const QString &reason);
    Q_INVOKABLE void submitMap(const QVariantMap &payload);
    Q_INVOKABLE QString sectionBody(const QString &type) const;
    Q_INVOKABLE bool sendChat(const QString &text);

signals:
    void modeChanged();
    void stateChanged();
    void actorChanged();
    void sourceChanged();
    void haltRequested(const QString &reason);
    void accepted(const QVariantMap &payload);
    void turnCompleted(bool ok);
    void busyChanged();
    void genaiReadyChanged();

private:
    void syncFromCore();
    void appendChat(const QString &qualifier, const QString &body);
    void requestGenAi(const QString &hostText);
    void onGenAiFinished(bool ok, const QString &text, const QString &interactionId,
                         const QString &error, const QString &usedModel);

    NodeEngine m_node;
    SectionListModel m_model;
    QString m_source;
    GenAiClient m_genai;
    QString m_previousInteractionId;
};

} // namespace ocsnode
