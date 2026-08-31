#pragma once

#include "ocsnode/NodeEngine.h"
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

    Q_INVOKABLE bool loadText(const QString &text);
    Q_INVOKABLE QString emitText() const;
    Q_INVOKABLE void requestHalt(const QString &reason);
    Q_INVOKABLE void submitMap(const QVariantMap &payload);
    Q_INVOKABLE QString sectionBody(const QString &type) const;

signals:
    void modeChanged();
    void stateChanged();
    void actorChanged();
    void sourceChanged();
    void haltRequested(const QString &reason);
    void accepted(const QVariantMap &payload);

private:
    void syncFromCore();

    NodeEngine m_node;
    SectionListModel m_model;
    QString m_source;
};

} // namespace ocsnode
