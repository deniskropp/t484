#include "ocsnode/qt/SectionListModel.h"

namespace ocsnode {

SectionListModel::SectionListModel(QObject *parent)
    : QAbstractListModel(parent)
{
}

void SectionListModel::resetFrom(const std::vector<Section> &sections)
{
    beginResetModel();
    m_rows.clear();
    m_rows.reserve(int(sections.size()));
    for (const auto &s : sections)
        m_rows.push_back(s);
    endResetModel();
    emit countChanged();
}

int SectionListModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_rows.size();
}

QVariant SectionListModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= m_rows.size())
        return {};
    const auto &s = m_rows.at(index.row());
    switch (role) {
    case FamilyRole:
        return QString::fromStdString(s.family);
    case PathRole:
        return QString::fromStdString(s.path);
    case TypeRole:
        return QString::fromStdString(s.type());
    case QualifierRole:
        return QString::fromStdString(s.qualifier);
    case BodyRole:
        return QString::fromStdString(s.body);
    case LineRole:
        return s.line;
    default:
        return {};
    }
}

QHash<int, QByteArray> SectionListModel::roleNames() const
{
    return {
        {FamilyRole, "family"},
        {PathRole, "path"},
        {TypeRole, "type"},
        {QualifierRole, "qualifier"},
        {BodyRole, "body"},
        {LineRole, "line"},
    };
}

} // namespace ocsnode
