pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.ii.sessionScreen

FocusScope {
    id: root

    required property GreeterContext context
    property string subtitle

    signal closed()

    Component.onCompleted: sleepButton.forceActiveFocus()

    function run(action) {
        Greeter.power(action);
        root.closed();
    }

    HoverHandler {
        // Scene changes send synthetic hover updates without real movement
        property point lastPos: Qt.point(-1, -1)
        onPointChanged: {
            const pos = point.position;
            const moved = lastPos.x >= 0 && Math.abs(pos.x - lastPos.x) + Math.abs(pos.y - lastPos.y) > 2;
            lastPos = pos;
            if (moved) root.context.reveal();
        }
    }

    Keys.onPressed: event => {
        if (event.key !== Qt.Key_Escape) return;
        root.closed();
        event.accepted = true;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closed()
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: 15

        ColumnLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            StyledText {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font {
                    family: Appearance.font.family.title
                    pixelSize: Appearance.font.pixelSize.title
                    variableAxes: Appearance.font.variableAxes.title
                }
                text: "Session"
            }

            StyledText {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Appearance.font.pixelSize.normal
                text: "Arrow keys to navigate, Enter to select\nEsc or click anywhere to cancel"
            }
        }

        GridLayout {
            id: buttonGrid
            Layout.alignment: Qt.AlignHCenter
            columns: 2
            columnSpacing: 15
            rowSpacing: 15

            Keys.onPressed: event => {
                root.context.reveal();
                let step = 0;
                if (event.key === Qt.Key_Left) step = -1;
                else if (event.key === Qt.Key_Right) step = 1;
                else if (event.key === Qt.Key_Up) step = -columns;
                else if (event.key === Qt.Key_Down) step = columns;
                if (step === 0) return;
                event.accepted = true;

                const buttons = Array.from(buttonGrid.children).filter(b => b.visible);
                const index = buttons.findIndex(b => b.activeFocus);
                const target = index + step;
                const sameRow = Math.floor(target / columns) === Math.floor(index / columns);
                if (index < 0 || target < 0 || target >= buttons.length) return;
                if (Math.abs(step) === 1 && !sameRow) return;
                buttons[target].forceActiveFocus();
            }

            MenuButton {
                id: sleepButton
                buttonIcon: "dark_mode"
                buttonText: "Sleep"
                onClicked: root.run("suspend")
            }
            MenuButton {
                buttonIcon: "downloading"
                buttonText: "Hibernate"
                onClicked: root.run("hibernate")
            }
            MenuButton {
                buttonIcon: "power_settings_new"
                buttonText: "Shutdown"
                onClicked: root.run("poweroff")
            }
            MenuButton {
                buttonIcon: "restart_alt"
                buttonText: "Reboot"
                onClicked: root.run("reboot")
            }
        }

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            color: Appearance.colors.colTooltip
            clip: true
            radius: Appearance.rounding.normal
            implicitHeight: subtitleText.implicitHeight + 10 * 2
            implicitWidth: subtitleText.implicitWidth + 15 * 2

            Behavior on implicitWidth {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

            StyledText {
                id: subtitleText
                anchors.centerIn: parent
                color: Appearance.colors.colOnTooltip
                text: root.subtitle
            }
        }
    }

    component MenuButton: SessionActionButton {
        onFocusChanged: {
            if (focus)
                root.subtitle = buttonText;
        }
    }
}
