#include "ocsnode/qt/EventLogModel.h"

#include <QDateTime>

namespace ocsnode {

EventLogModel::EventLogModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

void EventLogModel::setMaxRows(int n)
{
    const int clamped = n < 10 ? 10 : n;
    if (m_maxRows == clamped)
        return;
    m_maxRows = clamped;
    if (m_rows.size() > m_maxRows) {
        beginRemoveRows(QModelIndex(), m_maxRows, m_rows.size() - 1);
        m_rows.resize(m_maxRows);
        endRemoveRows();
        emit countChanged();
    }
    emit maxRowsChanged();
}

int EventLogModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_rows.size();
}

QVariant EventLogModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size())
        return {};
    const auto &row = m_rows.at(index.row());
    switch (role) {
    case TimeRole:
        return row.time;
    case EventRole:
        return row.event;
    case DetailsRole:
        return row.details;
    case LevelRole:
        return row.level;
    default:
        return {};
    }
}

QHash<int, QByteArray> EventLogModel::roleNames() const
{
    return {
        {TimeRole, "time"},
        {EventRole, "event"},
        {DetailsRole, "details"},
        {LevelRole, "level"},
    };
}

void EventLogModel::appendEvent(const QString &level,
                                const QString &event,
                                const QString &details)
{
    Row row;
    row.time = QDateTime::currentDateTime().toString(QStringLiteral("HH:mm:ss"));
    row.event = event;
    row.details = details;
    row.level = level.isEmpty() ? QStringLiteral("info") : level;

    beginInsertRows(QModelIndex(), 0, 0);
    m_rows.prepend(row);
    endInsertRows();

    if (m_rows.size() > m_maxRows) {
        beginRemoveRows(QModelIndex(), m_maxRows, m_rows.size() - 1);
        m_rows.resize(m_maxRows);
        endRemoveRows();
    }
    emit countChanged();
}

void EventLogModel::clear()
{
    if (m_rows.isEmpty())
        return;
    beginResetModel();
    m_rows.clear();
    endResetModel();
    emit countChanged();
}

} // namespace ocsnode
