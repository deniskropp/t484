#include "ocsnode/qt/ProtocolEngineQt.h"

namespace ocsnode {

ProtocolEngineQt::ProtocolEngineQt(QObject *parent)
    : QObject(parent)
{
    m_node.protocol().setHaltHandler([this](const std::string &reason) {
        emit haltRequested(QString::fromStdString(reason));
    });
}

QString ProtocolEngineQt::mode() const
{
    return QString::fromStdString(m_node.protocol().state().mode);
}

void ProtocolEngineQt::setMode(const QString &mode)
{
    if (this->mode() == mode)
        return;
    m_node.protocol().setMode(mode.toStdString());
    syncFromCore();
    emit modeChanged();
}

QString ProtocolEngineQt::status() const
{
    return QString::fromStdString(m_node.protocol().state().status);
}

double ProtocolEngineQt::coherence() const
{
    return m_node.protocol().state().coherence;
}

bool ProtocolEngineQt::gated() const
{
    return m_node.protocol().state().gated;
}

QString ProtocolEngineQt::haltReason() const
{
    return QString::fromStdString(m_node.protocol().state().haltReason);
}

QString ProtocolEngineQt::currentTasId() const
{
    return QString::fromStdString(m_node.protocol().state().currentTasId);
}

int ProtocolEngineQt::activeSteps() const
{
    return m_node.protocol().state().activeSteps;
}

QString ProtocolEngineQt::actor() const
{
    return QString::fromStdString(m_node.actor());
}

void ProtocolEngineQt::setActor(const QString &actor)
{
    if (this->actor() == actor)
        return;
    m_node.setActor(actor.toStdString());
    emit actorChanged();
}

QString ProtocolEngineQt::sourceText() const
{
    return m_source;
}

int ProtocolEngineQt::errorCount() const
{
    return int(m_node.protocol().errors().size());
}

bool ProtocolEngineQt::loadText(const QString &text)
{
    m_source = text;
    auto result = m_node.ingest(text.toStdString());
    syncFromCore();
    emit sourceChanged();
    return result.ok();
}

QString ProtocolEngineQt::emitText() const
{
    return QString::fromStdString(m_node.protocol().emitText());
}

void ProtocolEngineQt::requestHalt(const QString &reason)
{
    m_node.protocol().requestHalt(reason.toStdString());
    syncFromCore();
}

void ProtocolEngineQt::submitMap(const QVariantMap &payload)
{
    Section s;
    const auto type = payload.value(QStringLiteral("sectionType")).toString();
    const auto slash = type.indexOf('/');
    if (slash < 0) {
        s.family = type.toStdString();
    } else {
        s.family = type.left(slash).toStdString();
        s.path = type.mid(slash + 1).toStdString();
    }
    s.qualifier = payload.value(QStringLiteral("qualifier")).toString().toStdString();
    if (s.qualifier.empty())
        s.qualifier = payload.value(QStringLiteral("molecule")).toString().toStdString();
    s.body = payload.value(QStringLiteral("body")).toString().toStdString();
    if (s.body.empty())
        s.body = payload.value(QStringLiteral("formula")).toString().toStdString();
    m_node.protocol().submit(s);
    syncFromCore();
    emit accepted(payload);
}

QString ProtocolEngineQt::sectionBody(const QString &type) const
{
    if (const auto *s = m_node.protocol().findByType(type.toStdString()))
        return QString::fromStdString(s->body);
    return {};
}

void ProtocolEngineQt::syncFromCore()
{
    m_model.resetFrom(m_node.protocol().sections());
    m_source = QString::fromStdString(m_node.protocol().emitText());
    emit stateChanged();
    emit modeChanged();
    emit sourceChanged();
}

} // namespace ocsnode
