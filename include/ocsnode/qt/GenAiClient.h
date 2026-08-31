#pragma once

#include <QByteArray>
#include <QHash>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QObject>
#include <QString>

namespace ocsnode {

// Google GenAI Interactions API (latest). REST: POST /v1beta/interactions
// Model default: gemini-3.7-flash. Auth: x-goog-api-key from GEMINI_API_KEY.
class GenAiClient : public QObject
{
    Q_OBJECT

public:
    explicit GenAiClient(QObject *parent = nullptr);

    QString apiKey() const;
    QString apiKeySource() const;
    QString model() const;
    bool ready() const { return !apiKey().isEmpty(); }
    bool busy() const { return m_reply != nullptr; }

    static QHash<QString, QString> parseDotEnv(const QByteArray &raw);
    static QString debugReport();

    void abort();

    // previousInteractionId may be empty (first turn).
    void create(const QString &input, const QString &systemInstruction,
                const QString &previousInteractionId);

    static QString extractOutputText(const QByteArray &json, QString *interactionId,
                                     QString *status, QString *errorMessage);

signals:
    void finished(bool ok, const QString &text, const QString &interactionId,
                  const QString &error, const QString &usedModel);
    void busyChanged();

private:
    void onReplyFinished();
    void postAttempt();
    QStringList modelChain() const;
    QString currentModel() const;

    QNetworkAccessManager m_nam;
    QNetworkReply *m_reply = nullptr;
    QString m_input;
    QString m_systemInstruction;
    QString m_previousInteractionId;
    int m_attempt = 0;
};

} // namespace ocsnode
