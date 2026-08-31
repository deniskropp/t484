#include "ocsnode/qt/GenAiClient.h"

#include <cstdlib>
#include <iostream>

static int g_failed = 0;
static int g_passed = 0;

static void check(bool cond, const char *name)
{
    if (cond) {
        ++g_passed;
        std::cout << "  PASS  " << name << "\n";
    } else {
        ++g_failed;
        std::cout << "  FAIL  " << name << "\n";
    }
}

int main()
{
    std::cout << "ocsnode_genai_tests\n";

    const QByteArray okJson = R"({
      "id": "v1_abc",
      "status": "completed",
      "steps": [
        {"type": "thought", "signature": "x"},
        {"type": "model_output", "content": [
          {"type": "text", "text": "Hello from Gemini"}
        ]}
      ],
      "object": "interaction",
      "model": "gemini-3.7-flash"
    })";

    QString id;
    QString status;
    QString err;
    const auto text = ocsnode::GenAiClient::extractOutputText(okJson, &id, &status, &err);
    check(text == QStringLiteral("Hello from Gemini"), "extract model_output text");
    check(id == QStringLiteral("v1_abc"), "extract interaction id");
    check(status == QStringLiteral("completed"), "extract status");
    check(err.isEmpty(), "no error on completed");

    const QByteArray apiErr = R"({"error":{"message":"API key not valid","code":400}})";
    QString e2;
    const auto t2 = ocsnode::GenAiClient::extractOutputText(apiErr, nullptr, nullptr, &e2);
    check(t2.isEmpty() && e2.contains(QStringLiteral("API key")), "api error message");

    const QByteArray bad = "not-json";
    QString e3;
    const auto t3 = ocsnode::GenAiClient::extractOutputText(bad, nullptr, nullptr, &e3);
    check(t3.isEmpty() && !e3.isEmpty(), "invalid json");

    const auto envMap = ocsnode::GenAiClient::parseDotEnv(
        "export GEMINI_API_KEY=\"abc\"\n"
        "# comment\n"
        "GOOGLE_AI_API_KEY=xyz\n");
    check(envMap.value(QStringLiteral("GEMINI_API_KEY")) == QStringLiteral("abc"),
          "parseDotEnv quoted GEMINI_API_KEY");
    check(envMap.value(QStringLiteral("GOOGLE_AI_API_KEY")) == QStringLiteral("xyz"),
          "parseDotEnv GOOGLE_AI_API_KEY");

    std::cout << g_passed << " passed, " << g_failed << " failed\n";
    return g_failed ? EXIT_FAILURE : EXIT_SUCCESS;
}
