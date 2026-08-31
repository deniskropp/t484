#pragma once

#include "ocsnode/Section.h"

#include <QAbstractListModel>
#include <QVector>
#include <string>
#include <vector>

namespace ocsnode {

class SectionListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    enum Roles {
        FamilyRole = Qt::UserRole + 1,
        PathRole,
        TypeRole,
        QualifierRole,
        BodyRole,
        LineRole
    };

    explicit SectionListModel(QObject *parent = nullptr);

    void resetFrom(const std::vector<Section> &sections);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

signals:
    void countChanged();

private:
    QVector<Section> m_rows;
};

} // namespace ocsnode
