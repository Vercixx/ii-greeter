pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Quickshell.Services.UPower
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.lock

MouseArea {
    id: root
    required property GreeterContext context
    property Item openSelector: null

    function forceFieldFocus() {
        passwordBox.forceActiveFocus();
    }
    Connections {
        target: root.context
        function onShouldReFocus() {
            root.forceFieldFocus();
        }
    }
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton
    onPressed: mouse => {
        root.openSelector = null;
        forceFieldFocus();
    }
    onPositionChanged: mouse => {
        forceFieldFocus();
    }

    property real toolbarScale: 0.9
    property real toolbarOpacity: 0
    Behavior on toolbarScale {
        NumberAnimation {
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }
    }
    Behavior on toolbarOpacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    Component.onCompleted: {
        forceFieldFocus();
        toolbarScale = 1;
        toolbarOpacity = 1;
    }

    Keys.onPressed: event => {
        root.context.resetClearTimer();
        if (event.key === Qt.Key_Escape) {
            if (Greeter.devMode && root.context.currentText.length === 0)
                Qt.quit();
            root.context.currentText = "";
            root.openSelector = null;
        }
        forceFieldFocus();
    }

    Toolbar {
        id: mainIsland
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        ToolbarTextField {
            id: passwordBox
            Layout.rightMargin: -Layout.leftMargin
            placeholderText: {
                if (root.context.message.length > 0)
                    return root.context.message;
                return root.context.showFailure ? "Incorrect password" : "Enter password";
            }

            clip: true
            font.pixelSize: Appearance.font.pixelSize.small
            selectedTextColor: materialShapeChars ? "transparent" : Appearance.colors.colOnSecondaryContainer
            selectionColor: materialShapeChars ? "transparent" : Appearance.colors.colSecondaryContainer

            enabled: !root.context.inProgress
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData

            onTextChanged: root.context.currentText = this.text
            onAccepted: root.context.tryLogin()
            Connections {
                target: root.context
                function onCurrentTextChanged() {
                    passwordBox.text = root.context.currentText;
                }
            }

            Keys.onPressed: event => {
                root.context.resetClearTimer();
            }

            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: passwordBox.width - 8
                    height: passwordBox.height
                    radius: height / 2
                }
            }

            ErrorShakeAnimation {
                id: wrongPasswordShakeAnim
                target: passwordBox
            }
            Connections {
                target: root.context
                function onFailed() {
                    wrongPasswordShakeAnim.restart();
                }
            }

            property bool materialShapeChars: Config.options.lock.materialShapeChars
            color: ColorUtils.transparentize(Appearance.colors.colOnLayer1, materialShapeChars ? 1 : 0)
            Loader {
                active: passwordBox.materialShapeChars
                anchors {
                    fill: parent
                    leftMargin: passwordBox.padding
                    rightMargin: passwordBox.padding
                }
                sourceComponent: PasswordChars {
                    length: root.context.currentText.length
                    selectionStart: passwordBox.selectionStart
                    selectionEnd: passwordBox.selectionEnd
                    cursorPosition: passwordBox.cursorPosition
                }
            }
        }

        ToolbarButton {
            id: confirmButton
            implicitWidth: height
            toggled: true
            enabled: !root.context.inProgress && Greeter.currentSession !== null
            colBackgroundToggled: Appearance.colors.colPrimary

            onClicked: root.context.tryLogin()

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                iconSize: 24
                text: "arrow_right_alt"
                color: confirmButton.enabled ? Appearance.colors.colOnPrimary : Appearance.colors.colSubtext
            }
        }
    }

    Toolbar {
        id: leftIsland
        anchors {
            right: mainIsland.left
            top: mainIsland.top
            bottom: mainIsland.bottom
            rightMargin: 10
        }
        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        Selector {
            symbol: "account_circle"
            options: Greeter.users.map(u => ({ key: u.name, label: u.displayName }))
            currentKey: Greeter.user
            onPicked: key => Greeter.chosenUser = key
        }

        Selector {
            symbol: "desktop_windows"
            options: Greeter.sessions.map(s => ({ key: s.path, label: s.name }))
            currentKey: Greeter.session
            onPicked: key => Greeter.chosenSession = key
        }
    }

    Toolbar {
        id: rightIsland
        anchors {
            left: mainIsland.right
            top: mainIsland.top
            bottom: mainIsland.bottom
            leftMargin: 10
        }

        scale: root.toolbarScale
        opacity: root.toolbarOpacity

        IconAndTextPair {
            readonly property var battery: UPower.displayDevice
            visible: battery.isLaptopBattery
            icon: battery.state === UPowerDeviceState.Charging ? "bolt" : "battery_android_full"
            text: Math.round(battery.percentage * 100)
        }

        IconToolbarButton {
            onClicked: Greeter.power("suspend")
            text: "dark_mode"
        }

        IconToolbarButton {
            onClicked: Greeter.power("poweroff")
            text: "power_settings_new"
        }

        IconToolbarButton {
            onClicked: Greeter.power("reboot")
            text: "restart_alt"
        }
    }

    component Selector: ToolbarButton {
        id: selector
        required property string symbol
        required property var options
        required property string currentKey
        signal picked(string key)

        readonly property bool open: root.openSelector === selector
        implicitWidth: selectorRow.implicitWidth + 24
        onClicked: root.openSelector = open || options.length < 2 ? null : selector

        contentItem: Row {
            id: selectorRow
            anchors.centerIn: parent
            spacing: 6
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                fill: 1
                text: selector.symbol
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                anchors.verticalCenter: parent.verticalCenter
                text: selector.options.find(o => o.key === selector.currentKey)?.label ?? ""
                color: Appearance.colors.colOnSurfaceVariant
            }
            MaterialSymbol {
                anchors.verticalCenter: parent.verticalCenter
                visible: selector.options.length > 1
                text: selector.open ? "expand_more" : "expand_less"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        StyledRectangularShadow {
            target: popup
            visible: popup.visible
        }
        Rectangle {
            id: popup
            visible: selector.open
            anchors {
                bottom: parent.top
                bottomMargin: 18
                horizontalCenter: parent.horizontalCenter
            }
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.normal
            implicitWidth: Math.max(popupColumn.implicitWidth, selector.width) + 16
            implicitHeight: popupColumn.implicitHeight + 16

            ColumnLayout {
                id: popupColumn
                anchors {
                    fill: parent
                    margins: 8
                }
                spacing: 2
                Repeater {
                    model: selector.options
                    delegate: RippleButton {
                        id: option
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: 40
                        buttonRadius: Appearance.rounding.full
                        toggled: option.modelData.key === selector.currentKey
                        colBackgroundToggled: Appearance.colors.colSecondaryContainer
                        colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
                        colRippleToggled: Appearance.colors.colSecondaryContainerActive
                        onClicked: {
                            selector.picked(option.modelData.key);
                            root.openSelector = null;
                            root.forceFieldFocus();
                        }
                        contentItem: StyledText {
                            leftPadding: 12
                            rightPadding: 12
                            text: option.modelData.label
                            color: option.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnSurfaceVariant
                        }
                    }
                }
            }
        }
    }

    component IconAndTextPair: Row {
        id: pair
        required property string icon
        required property string text
        property color color: Appearance.colors.colOnSurfaceVariant

        spacing: 4
        Layout.fillHeight: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            fill: 1
            text: pair.icon
            iconSize: Appearance.font.pixelSize.huge
            animateChange: true
            color: pair.color
        }
        StyledText {
            anchors.verticalCenter: parent.verticalCenter
            text: pair.text
            color: pair.color
        }
    }
}
