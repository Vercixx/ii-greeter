pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Greetd

Singleton {
    id: root

    readonly property bool devMode: !Greetd.available
    readonly property string dataDir: "/var/lib/ii-greeter"
    readonly property string home: Quickshell.env("HOME")
    readonly property string devConfigPath: `${Quickshell.env("XDG_CONFIG_HOME") || root.home + "/.config"}/illogical-impulse/config.json`
    readonly property string devColorsPath: `${Quickshell.env("XDG_STATE_HOME") || root.home + "/.local/state"}/quickshell/user/generated/colors.json`

    property var users: []
    property var sessions: []
    property var last: ({})
    property string chosenUser: ""
    property string chosenSession: ""

    readonly property string user: chosenUser
        || (users.some(u => u.name === last.user) ? last.user : (users[0]?.name ?? ""))
    readonly property string session: chosenSession
        || (sessions.some(s => s.path === last.session) ? last.session
            : (sessions.find(s => /hyprland/i.test(s.path))?.path ?? sessions[0]?.path ?? ""))
    readonly property var currentSession: sessions.find(s => s.path === session) ?? null

    readonly property string userDir: `${dataDir}/users/${user}`
    readonly property string configPath: devMode ? devConfigPath : (user ? `${userDir}/config.json` : "")
    readonly property string colorsPath: devMode ? devColorsPath : (user ? `${userDir}/colors.json` : "")

    function saveLast() {
        if (root.devMode) return;
        lastFile.setText(JSON.stringify({ user: root.user, session: root.session }));
    }

    function launchCommand() {
        const exec = root.currentSession.exec.replace(/\s+%[fFuUdDnNickvm]/g, "");
        return ["/bin/sh", "-c", `exec ${exec}`];
    }

    function launchEnvironment() {
        const s = root.currentSession;
        const desktopId = s.path.split("/").pop().replace(/\.desktop$/, "");
        const desktopNames = s.desktopNames.split(";").filter(Boolean).join(":") || desktopId;
        return ["XDG_SESSION_TYPE=wayland", `XDG_CURRENT_DESKTOP=${desktopNames}`, `XDG_SESSION_DESKTOP=${desktopId}`];
    }

    function power(action) {
        if (root.devMode) {
            console.log(`[Greeter] dev mode: skipping loginctl ${action}`);
            return;
        }
        Quickshell.execDetached(["loginctl", action]);
    }

    FileView {
        path: "/etc/passwd"
        onLoaded: {
            root.users = text().split("\n").map(line => line.split(":")).filter(f => {
                const uid = parseInt(f[2]);
                return f.length >= 7 && uid >= 1000 && uid < 60000 && !/(nologin|false)$/.test(f[6]);
            }).map(f => ({
                name: f[0],
                displayName: f[4].split(",")[0] || f[0]
            }));
        }
    }

    FileView {
        id: lastFile
        path: root.devMode ? "" : `${root.dataDir}/state/last.json`
        blockWrites: true
        onLoaded: {
            try {
                root.last = JSON.parse(text());
            } catch (e) {
                root.last = {};
            }
        }
    }

    Process {
        running: true
        command: ["sh", "-c", "grep -H -e '^Name=' -e '^Exec=' -e '^DesktopNames=' -e '^Hidden=' -e '^NoDisplay=' /usr/share/wayland-sessions/*.desktop /usr/local/share/wayland-sessions/*.desktop 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                const byPath = {};
                for (const line of text.split("\n")) {
                    const sep = line.indexOf(":");
                    const eq = line.indexOf("=", sep);
                    if (sep < 0 || eq < 0) continue;
                    const path = line.slice(0, sep);
                    if (!byPath[path])
                        byPath[path] = { path: path, name: "", exec: "", desktopNames: "", hidden: false };
                    const key = line.slice(sep + 1, eq);
                    const value = line.slice(eq + 1).trim();
                    if (key === "Name" && !byPath[path].name) byPath[path].name = value;
                    else if (key === "Exec" && !byPath[path].exec) byPath[path].exec = value;
                    else if (key === "DesktopNames") byPath[path].desktopNames = value;
                    else if (value === "true") byPath[path].hidden = true;
                }
                root.sessions = Object.values(byPath).filter(s => s.exec && !s.hidden);
            }
        }
    }
}
