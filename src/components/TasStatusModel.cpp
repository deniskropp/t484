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

QVariantList TasStatusModel::parseTasEntries(const QString &tasText, const QString &ptasText) const
{
    QVariantList list;
    auto parseLines = [&](const QString &text, const QString &kind) {
        const auto lines = text.split(QLatin1Char('\n'), Qt::SkipEmptyParts);
        for (const QString &rawLine : lines) {
            QString line = rawLine.trimmed();
            if (line.isEmpty())
                continue;

            QVariantMap item;
            item[QStringLiteral("kind")] = kind;
            item[QStringLiteral("raw")] = line;

            QString status = QStringLiteral("open");
            if (line.startsWith(QLatin1String("- [x] ")) || line.startsWith(QLatin1String("[x] "))) {
                status = QStringLiteral("done");
                line = line.mid(line.indexOf(QLatin1Char(']')) + 1).trimmed();
            } else if (line.startsWith(QLatin1String("- [ ] ")) || line.startsWith(QLatin1String("[ ] "))) {
                status = QStringLiteral("open");
                line = line.mid(line.indexOf(QLatin1Char(']')) + 1).trimmed();
            } else if (line.startsWith(QLatin1Char('-')) || line.startsWith(QLatin1Char('*'))) {
                line = line.mid(1).trimmed();
            }

            int spaceIdx = line.indexOf(QLatin1Char(' '));
            QString firstToken = spaceIdx > 0 ? line.left(spaceIdx) : line;
            QString remainder = spaceIdx > 0 ? line.mid(spaceIdx + 1).trimmed() : QString();

            QString id = firstToken;
            if (firstToken.contains(QLatin1String("-done"))) {
                status = QStringLiteral("done");
                id = firstToken.left(firstToken.indexOf(QLatin1String("-done")));
            } else if (firstToken.contains(QLatin1String("-partial")) || firstToken.contains(QLatin1String("-progress"))) {
                status = QStringLiteral("active");
                id = firstToken.left(firstToken.indexOf(QLatin1Char('-')));
            } else if (firstToken.contains(QLatin1String("-open")) || firstToken.contains(QLatin1String("-planned"))) {
                status = QStringLiteral("open");
                id = firstToken.left(firstToken.indexOf(QLatin1Char('-')));
            } else if (firstToken.contains(QLatin1String("-blocked"))) {
                status = QStringLiteral("blocked");
                id = firstToken.left(firstToken.indexOf(QLatin1String("-blocked")));
            } else if (firstToken.contains(QLatin1String("-policy"))) {
                status = QStringLiteral("policy");
                id = firstToken.left(firstToken.indexOf(QLatin1String("-policy")));
            } else if (kind == QStringLiteral("tas") && status == QStringLiteral("open")) {
                status = QStringLiteral("active");
            }

            item[QStringLiteral("id")] = id;
            item[QStringLiteral("title")] = remainder.isEmpty() ? firstToken : remainder;
            item[QStringLiteral("status")] = status;
            list.append(item);
        }
    };

    if (!tasText.isEmpty())
        parseLines(tasText, QStringLiteral("tas"));
    if (!ptasText.isEmpty())
        parseLines(ptasText, QStringLiteral("ptas"));

    return list;
}

void TasStatusModel::refreshTasModel(const QString &tasText, const QString &ptasText)
{
    setTasModel(parseTasEntries(tasText, ptasText));
}

} // namespace ocsnode
