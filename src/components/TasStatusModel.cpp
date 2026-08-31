#include "ocsnode/qt/TasStatusModel.h"
#include <QtGlobal>

namespace ocsnode {

TasStatusModel::TasStatusModel(QObject *parent)
    : QObject(parent)
{
}

void TasStatusModel::setSectionType(const QString &type)
{
    if (m_sectionType == type) return;
    m_sectionType = type;
    emit sectionTypeChanged();
}
void TasStatusModel::setStatus(const QString &s)
{
    if (m_status == s) return;
    m_status = s;
    emit statusChanged();
}
void TasStatusModel::setMode(const QString &m)
{
    if (m_mode == m) return;
    m_mode = m;
    emit modeChanged();
}
void TasStatusModel::setCoherence(qreal c)
{
    if (qFuzzyCompare(m_coherence, c)) return;
    m_coherence = c;
    emit coherenceChanged();
}
void TasStatusModel::setActiveSteps(int n)
{
    if (m_activeSteps == n) return;
    m_activeSteps = n;
    emit activeStepsChanged();
}
void TasStatusModel::setCurrentTasId(const QString &id)
{
    if (m_currentTasId == id) return;
    m_currentTasId = id;
    emit currentTasIdChanged();
}
void TasStatusModel::setTasModel(const QVariantList &model)
{
    if (m_tasModel == model) return;
    m_tasModel = model;
    emit tasModelChanged();
}
void TasStatusModel::setGated(bool g)
{
    if (m_gated == g) return;
    m_gated = g;
    emit gatedChanged();
}
void TasStatusModel::applyFromEngine(const QString &status, const QString &mode,
                                    qreal coherence, int steps, const QString &tasId, bool gated)
{
    setStatus(status);
    setMode(mode);
    setCoherence(coherence);
    setActiveSteps(steps);
    setCurrentTasId(tasId);
    setGated(gated);
}
void TasStatusModel::submitStatusUpdate(const QVariantMap &payload)
{
    emit accepted(payload);
    if (payload.value(QStringLiteral("halt")).toBool())
        emit haltRequested(payload.value(QStringLiteral("reason")).toString());
}

} // namespace ocsnode
