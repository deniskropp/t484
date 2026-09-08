#pragma once

#include <QString>
#include <QVariantMap>
#include <ocsnode/Section.h>

namespace ocsnode {

// ------------------------------------------------------------
// Trigger – input for a GenerativeWidget instance
// ------------------------------------------------------------
struct Trigger {
    QString type;               // e.g. "explore", "render"
    QVariantMap payload;        // free‑form key/value data

    // Optional helpers to convert to/from an OCS Section
    static Trigger fromSection(const Section &section);
    Section toSection() const;
};

// ------------------------------------------------------------
// Synthesis – result of executing a KickLang playbook
// ------------------------------------------------------------
struct Synthesis {
    QString templateText;        // Mustache‑style template
    QVariantMap context;        // Variables for template expansion

    // Very small renderer – expands Mustache‑style tags {{key}}
    QString render() const;
};

// ------------------------------------------------------------
// GenerativeWidgetSection – concrete OCS Section
// ------------------------------------------------------------
class GenerativeWidgetSection : public Section {
public:
    GenerativeWidgetSection() = default;
    explicit GenerativeWidgetSection(const Trigger &trigger,
                                     const Synthesis &synth);

    // Section interface
    QString name() const override { return "display/generative_widget"; }
    QString serialize() const override;
    static std::unique_ptr<GenerativeWidgetSection> deserialize(const QString &text);

    // Accessors
    const Trigger &trigger() const { return m_trigger; }
    const Synthesis &synthesis() const { return m_synthesis; }

private:
    Trigger m_trigger;
    Synthesis m_synthesis;
};

} // namespace ocsnode
