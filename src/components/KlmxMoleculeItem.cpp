#include "ocsnode/qt/KlmxMoleculeItem.h"
#include <QtGlobal>

namespace ocsnode {

KlmxMoleculeItem::KlmxMoleculeItem(QObject *parent)
    : QObject(parent)
{
}

void KlmxMoleculeItem::setSectionType(const QString &type)
{
    if (m_sectionType == type) return;
    m_sectionType = type;
    emit sectionTypeChanged();
}
void KlmxMoleculeItem::setMolecule(const QString &m)
{
    if (m_molecule == m) return;
    m_molecule = m;
    emit moleculeChanged();
}
void KlmxMoleculeItem::setFormula(const QString &f)
{
    if (m_formula == f) return;
    m_formula = f;
    emit formulaChanged();
}
void KlmxMoleculeItem::setModelName(const QString &n)
{
    if (m_modelName == n) return;
    m_modelName = n;
    emit modelNameChanged();
}
void KlmxMoleculeItem::setSpace(const QString &s)
{
    if (m_space == s) return;
    m_space = s;
    emit spaceChanged();
}
void KlmxMoleculeItem::setScope(const QString &s)
{
    if (m_scope == s) return;
    m_scope = s;
    emit scopeChanged();
}
void KlmxMoleculeItem::setReference(const QString &r)
{
    if (m_reference == r) return;
    m_reference = r;
    emit referenceChanged();
}
void KlmxMoleculeItem::setMode(const QString &m)
{
    if (m_mode == m) return;
    m_mode = m;
    emit modeChanged();
}
void KlmxMoleculeItem::setCoherence(qreal c)
{
    if (qFuzzyCompare(m_coherence, c)) return;
    m_coherence = c;
    emit coherenceChanged();
}
void KlmxMoleculeItem::setEditable(bool e)
{
    if (m_editable == e) return;
    m_editable = e;
    emit editableChanged();
}
void KlmxMoleculeItem::setValidationStatus(const QString &s)
{
    if (m_validationStatus == s) return;
    m_validationStatus = s;
    emit validationStatusChanged();
}
void KlmxMoleculeItem::submitMolecule(const QVariantMap &payload)
{
    emit accepted(payload);
}
void KlmxMoleculeItem::validateFormula()
{
    emit validationRequested(m_formula);
    if (m_formula.empty()) {
        setValidationStatus(QStringLiteral("invalid"));
        return;
    }
    const bool hasSigil = m_formula.contains(QString::fromUtf8("\xE2\xAB\xBB"));
    setValidationStatus(hasSigil ? QStringLiteral("valid") : QStringLiteral("invalid"));
}

} // namespace ocsnode
