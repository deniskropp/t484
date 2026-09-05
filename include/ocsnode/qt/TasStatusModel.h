#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>

namespace ocsnode {

class TasStatusModel : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString sectionType READ sectionType WRITE setSectionType NOTIFY sectionTypeChanged)
    Q_PROPERTY(QString status READ status WRITE setStatus NOTIFY statusChanged)
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(qreal coherence READ coherence WRITE setCoherence NOTIFY coherenceChanged)
    Q_PROPERTY(int activeSteps READ activeSteps WRITE setActiveSteps NOTIFY activeStepsChanged)
    Q_PROPERTY(QString currentTasId READ currentTasId WRITE setCurrentTasId NOTIFY currentTasIdChanged)
    Q_PROPERTY(QVariantList tasModel READ tasModel WRITE setTasModel NOTIFY tasModelChanged)
    Q_PROPERTY(bool gated READ gated WRITE setGated NOTIFY gatedChanged)

public:
    explicit TasStatusModel(QObject *parent = nullptr);

    QString sectionType() const { return m_sectionType; }
    void setSectionType(const QString &type);

    QString status() const { return m_status; }
    void setStatus(const QString &s);

    QString mode() const { return m_mode; }
    void setMode(const QString &m);

    qreal coherence() const { return m_coherence; }
    void setCoherence(qreal c);

    int activeSteps() const { return m_activeSteps; }
    void setActiveSteps(int n);

    QString currentTasId() const { return m_currentTasId; }
    void setCurrentTasId(const QString &id);

    QVariantList tasModel() const { return m_tasModel; }
    void setTasModel(const QVariantList &model);

    bool gated() const { return m_gated; }
    void setGated(bool g);

public slots:
    void applyFromEngine(const QString &status, const QString &mode,
                         qreal coherence, int steps, const QString &tasId, bool gated);
    void submitStatusUpdate(const QVariantMap &payload);
    Q_INVOKABLE QVariantList parseTasEntries(const QString &tasText, const QString &ptasText = QString()) const;
    Q_INVOKABLE void refreshTasModel(const QString &tasText, const QString &ptasText = QString());

signals:
    void sectionTypeChanged();
    void statusChanged();
    void modeChanged();
    void coherenceChanged();
    void activeStepsChanged();
    void currentTasIdChanged();
    void tasModelChanged();
    void gatedChanged();
    void accepted(const QVariantMap &payload);
    void haltRequested(const QString &reason);

private:
    QString m_sectionType = QStringLiteral("display/tas-status");
    QString m_status = QStringLiteral("idle");
    QString m_mode = QStringLiteral("Hybrid");
    qreal m_coherence = 1.0;
    int m_activeSteps = 0;
    QString m_currentTasId;
    QVariantList m_tasModel;
    bool m_gated = false;
};

} // namespace ocsnode
