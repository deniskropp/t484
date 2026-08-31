#pragma once

#include <QObject>
#include <QString>
#include <QVariantMap>

namespace ocsnode {

class KlmxMoleculeItem : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString sectionType READ sectionType WRITE setSectionType NOTIFY sectionTypeChanged)
    Q_PROPERTY(QString molecule READ molecule WRITE setMolecule NOTIFY moleculeChanged)
    Q_PROPERTY(QString formula READ formula WRITE setFormula NOTIFY formulaChanged)
    Q_PROPERTY(QString modelName READ modelName WRITE setModelName NOTIFY modelNameChanged)
    Q_PROPERTY(QString space READ space WRITE setSpace NOTIFY spaceChanged)
    Q_PROPERTY(QString scope READ scope WRITE setScope NOTIFY scopeChanged)
    Q_PROPERTY(QString reference READ reference WRITE setReference NOTIFY referenceChanged)
    Q_PROPERTY(QString mode READ mode WRITE setMode NOTIFY modeChanged)
    Q_PROPERTY(qreal coherence READ coherence WRITE setCoherence NOTIFY coherenceChanged)
    Q_PROPERTY(bool editable READ editable WRITE setEditable NOTIFY editableChanged)
    Q_PROPERTY(QString validationStatus READ validationStatus WRITE setValidationStatus NOTIFY validationStatusChanged)

public:
    explicit KlmxMoleculeItem(QObject *parent = nullptr);

    QString sectionType() const { return m_sectionType; }
    void setSectionType(const QString &type);
    QString molecule() const { return m_molecule; }
    void setMolecule(const QString &m);
    QString formula() const { return m_formula; }
    void setFormula(const QString &f);
    QString modelName() const { return m_modelName; }
    void setModelName(const QString &n);
    QString space() const { return m_space; }
    void setSpace(const QString &s);
    QString scope() const { return m_scope; }
    void setScope(const QString &s);
    QString reference() const { return m_reference; }
    void setReference(const QString &r);
    QString mode() const { return m_mode; }
    void setMode(const QString &m);
    qreal coherence() const { return m_coherence; }
    void setCoherence(qreal c);
    bool editable() const { return m_editable; }
    void setEditable(bool e);
    QString validationStatus() const { return m_validationStatus; }
    void setValidationStatus(const QString &s);

public slots:
    void submitMolecule(const QVariantMap &payload);
    void validateFormula();

signals:
    void sectionTypeChanged();
    void moleculeChanged();
    void formulaChanged();
    void modelNameChanged();
    void spaceChanged();
    void scopeChanged();
    void referenceChanged();
    void modeChanged();
    void coherenceChanged();
    void editableChanged();
    void validationStatusChanged();
    void accepted(const QVariantMap &payload);
    void validationRequested(const QString &formula);

private:
    QString m_sectionType = QStringLiteral("context/klmx");
    QString m_molecule = QStringLiteral("Kick/Lang");
    QString m_formula;
    QString m_modelName = QStringLiteral("OCS/Node Engine");
    QString m_space = QStringLiteral("OCS/Node");
    QString m_scope = QStringLiteral("global");
    QString m_reference = QStringLiteral("deniskropp/t484");
    QString m_mode = QStringLiteral("Hybrid");
    qreal m_coherence = 1.0;
    bool m_editable = true;
    QString m_validationStatus = QStringLiteral("idle");
};

} // namespace ocsnode
