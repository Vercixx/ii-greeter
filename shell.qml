import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.services

ShellRoot {
    GreeterContext {
        id: greeterContext
    }

    Component.onCompleted: MaterialThemeLoader.reapplyTheme()

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property ShellScreen modelData
            screen: modelData
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "ii-greeter"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: "black"

            GreeterBackground {
                anchors.fill: parent
            }

            GreeterSurface {
                anchors.fill: parent
                context: greeterContext
            }
        }
    }
}
