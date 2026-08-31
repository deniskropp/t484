pragma Singleton
import QtQuick

// OCS/Node visual system — t484 Slate.
// Dark is the product theme (#0f172a + cyan/violet). Light is the accessibility twin.
// No QML surface should hard-code a hex after this file exists.

QtObject {
    id: theme

    property string name: "Dark"
    readonly property bool light: name === "Light"

    readonly property string fontUi: "Inter"
    readonly property string fontMono: "Fira Code"

    readonly property int radius: 8
    readonly property int radiusSm: 4
    readonly property int radiusPill: 12
    readonly property int borderWidth: 1
    readonly property int glowWidth: 1

    readonly property color bg: light ? "#f1f5f9" : "#0f172a"
    readonly property color bgRaised: light ? "#ffffff" : "#111827"
    readonly property color bgSunken: light ? "#e2e8f0" : "#0b1220"
    readonly property color bgPanel: light ? "#f8fafc" : "#1e293b"
    readonly property color bgChrome: light ? "#e2e8f0" : "#020617"
    readonly property color bgHover: light ? "#e2e8f0" : "#1e293b"
    readonly property color stripeEven: light ? "#ffffff" : "#111827"
    readonly property color stripeOdd: light ? "#f1f5f9" : "#0f172a"

    readonly property color border: light ? "#cbd5e1" : "#334155"
    readonly property color borderSubtle: light ? "#e2e8f0" : "#1e293b"
    readonly property color borderGlow: light ? "#67e8f9" : "#22d3ee"

    readonly property color text: light ? "#0f172a" : "#e2e8f0"
    readonly property color textMuted: light ? "#475569" : "#94a3b8"
    readonly property color textFaint: light ? "#64748b" : "#64748b"

    readonly property color cyan: "#22d3ee"
    readonly property color cyanSoft: "#67e8f9"
    readonly property color violet: "#a78bfa"
    readonly property color violetDeep: "#7c3aed"
    readonly property color teal: "#14b8a6"
    readonly property color amber: "#f59e0b"
    readonly property color emerald: "#34d399"
    readonly property color danger: "#f43f5e"
    readonly property color warning: "#fbbf24"
    readonly property color success: "#34d399"
    readonly property color info: "#38bdf8"

    readonly property color hostFill: light ? "#ecfeff" : "#134e4a"
    readonly property color hostBorder: "#2dd4bf"
    readonly property color kickForgeFill: light ? "#fff7ed" : "#1c1408"
    readonly property color kickForgeBorder: "#f59e0b"
    readonly property color kickFlowFill: light ? "#ecfeff" : "#042f2e"
    readonly property color kickFlowBorder: "#22d3ee"
    readonly property color kickGuardFill: light ? "#f5f3ff" : "#1e1033"
    readonly property color kickGuardBorder: "#a78bfa"

    readonly property color gateFill: light ? "#ffe4e6" : "#3d1f24"
    readonly property color meterTrack: light ? "#cbd5e1" : "#1e293b"

    function apply(themeName) {
        if (themeName && themeName.length)
            name = themeName
    }

    function coherenceColor(v) {
        if (v > 0.85)
            return success
        if (v > 0.6)
            return warning
        return danger
    }

    function statusColor(status) {
        switch (status) {
        case "running": return emerald
        case "gated": return amber
        case "complete": return cyan
        case "error": return danger
        default: return textMuted
        }
    }

    function levelColor(level) {
        switch (level) {
        case "error": return danger
        case "warning": return warning
        case "genai": return violet
        case "protocol": return cyan
        default: return emerald
        }
    }

    function roleAccent(qualifier, family, isHost) {
        const q = qualifier ? qualifier.toLowerCase() : ""
        if (isHost || q === "host" || q === "user")
            return hostBorder
        if (q.indexOf("kickforge") === 0 || q === "forge")
            return kickForgeBorder
        if (q.indexOf("kickflow") === 0 || q === "flow")
            return kickFlowBorder
        if (q.indexOf("kickguard") === 0 || q === "guard")
            return kickGuardBorder
        switch (family) {
        case "flow": return violet
        case "display": return emerald
        case "query": return amber
        case "cmd": return danger
        case "data": return cyanSoft
        case "context": return teal
        case "protocol": return textMuted
        default: return textMuted
        }
    }

    function roleFill(qualifier, family, isHost) {
        const q = qualifier ? qualifier.toLowerCase() : ""
        if (isHost || q === "host" || q === "user")
            return hostFill
        if (q.indexOf("kickforge") === 0 || q === "forge")
            return kickForgeFill
        if (q.indexOf("kickflow") === 0 || q === "flow")
            return kickFlowFill
        if (q.indexOf("kickguard") === 0 || q === "guard")
            return kickGuardFill
        return isHost ? hostFill : bgRaised
    }
}
