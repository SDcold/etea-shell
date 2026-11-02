pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

// The weather where you are, from Open-Meteo: no account, no key. The place is the city
// you gave the widget, or else a rough guess from your connection. It only asks while
// the weather widget is out, and then every twenty minutes.
Singleton {
    id: root

    readonly property bool wanted: Desk.shown.includes("weather")
    readonly property string city: Desk.entry("weather").city ?? ""

    property string place: "" // the name we show
    property var spot: null // { latitude, longitude }
    property bool known: false
    property real temperature: 0
    property int code: 0
    property bool day: true
    property var hours: [] // the next few hours: { time, temperature, code, day }
    property string failed: ""

    // What a weather code looks like and how we say it
    function look(code, day) {
        if (code === 0)
            return { icon: day ? "sun" : "moon", label: Lang.t("Ciel dégagé"), tint: day ? "#ffc98a" : "#9aa0e8" };
        if (code <= 2)
            return { icon: day ? "cloud-sun" : "cloud-moon", label: Lang.t("Quelques nuages"), tint: day ? "#f3d3a0" : "#a6a8de" };
        if (code === 3)
            return { icon: "cloud", label: Lang.t("Couvert"), tint: "#b4b8c8" };
        if (code === 45 || code === 48)
            return { icon: "fog", label: Lang.t("Brouillard"), tint: "#a9a4ad" };
        if (code >= 51 && code <= 57)
            return { icon: "drizzle", label: Lang.t("Bruine"), tint: "#9cc0e0" };
        if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82))
            return { icon: "rain", label: Lang.t("Pluie"), tint: "#8fb8e8" };
        if ((code >= 71 && code <= 77) || code === 85 || code === 86)
            return { icon: "snow", label: Lang.t("Neige"), tint: "#dfe8f5" };
        if (code >= 95)
            return { icon: "storm", label: Lang.t("Orage"), tint: "#b9a2f0" };
        return { icon: "cloud", label: Lang.t("Nuageux"), tint: "#b4b8c8" };
    }

    function refresh() {
        if (!wanted)
            return;
        failed = "";
        if (city) {
            locator.command = ["curl", "-sf", "--max-time", "15", "-G", "https://geocoding-api.open-meteo.com/v1/search", "--data-urlencode", `name=${city}`, "-d", "count=1", "-d", `language=${Lang.code}`];
        } else {
            locator.command = ["curl", "-sf", "--max-time", "15", "https://ipinfo.io/json"];
        }
        locator.running = true;
    }

    onWantedChanged: refresh()
    onCityChanged: {
        spot = null;
        refresh();
    }

    // First where, then what the sky is doing there
    Process {
        id: locator

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const answer = JSON.parse(text);
                    if (root.city) {
                        const found = answer.results?.[0];
                        if (!found)
                            throw new Error("unknown city");
                        root.spot = { latitude: found.latitude, longitude: found.longitude };
                        root.place = found.name;
                    } else {
                        const [latitude, longitude] = answer.loc.split(",").map(Number);
                        root.spot = { latitude: latitude, longitude: longitude };
                        root.place = answer.city ?? "";
                    }
                    forecast.running = true;
                } catch (error) {
                    root.failed = root.city ? Lang.t("Ville introuvable.") : Lang.t("Pas de réseau.");
                }
            }
        }
    }

    Process {
        id: forecast

        command: root.spot ? ["curl", "-sf", "--max-time", "15", `https://api.open-meteo.com/v1/forecast?latitude=${root.spot.latitude}&longitude=${root.spot.longitude}&current=temperature_2m,weather_code,is_day&hourly=temperature_2m,weather_code,is_day&forecast_hours=7&timezone=auto`] : []
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const answer = JSON.parse(text);
                    root.temperature = answer.current.temperature_2m;
                    root.code = answer.current.weather_code;
                    root.day = answer.current.is_day === 1;
                    const hourly = answer.hourly;
                    root.hours = hourly.time.slice(1).map((time, i) => ({
                        time: new Date(time),
                        temperature: hourly.temperature_2m[i + 1],
                        code: hourly.weather_code[i + 1],
                        day: hourly.is_day[i + 1] === 1
                    }));
                    root.known = true;
                } catch (error) {
                    root.failed = Lang.t("Pas de réseau.");
                }
            }
        }
    }

    Timer {
        running: root.wanted
        repeat: true
        interval: 20 * 60 * 1000
        onTriggered: root.refresh()
    }

    Component.onCompleted: refresh()
}
