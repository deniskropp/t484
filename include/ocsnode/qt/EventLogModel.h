#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QVector>

namespace ocsnode {

class EventLogModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(int maxRows READ maxRows WRITE setMaxRows NOTIFY maxRowsChanged)

public:
    enum Roles {
        TimeRole = Qt::UserRole + 1,
        EventRole,
        DetailsRole,
        LevelRole
    };

    struct Row {
        QString time;
        QString event;
        QString details;
        QString level;
    };

    explicit EventLogModel(QObject *parent = nullptr);

    int maxRows() const { return m_maxRows; }
    void setMaxRows(int n);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void appendEvent(const QString &level,
                                 const QString &event,
                                 const QString &details);
    Q_INVOKABLE void clear();

signals:
    void countChanged();
    void maxRowsChanged();

private:
    QVector<Row> m_rows;
    int m_maxRows = 200;
};

} // namespace ocsnode
