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
    readonly property bool revealed: context.revealed
    property Item openSelector: null
    property bool sessionMenuOpen: false

    onRevealedChanged: {
        if (revealed) return;
        openSelector = null;
        sessionMenuOpen = false;
        forceFieldFocus();
    }

    function forceFieldFocus() {
        if (root.sessionMenuOpen) return;
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
        root.context.reveal();
        root.openSelector = null;
        forceFieldFocus();
    }
    // Mapping the surface under a still cursor also sends a hover event
    property point lastMousePos: Qt.point(-1, -1)
    onPositionChanged: mouse => {
        const moved = lastMousePos.x >= 0 && Math.abs(mouse.x - lastMousePos.x) + Math.abs(mouse.y - lastMousePos.y) > 2;
        lastMousePos = Qt.point(mouse.x, mouse.y);
        if (moved) root.context.reveal();
        forceFieldFocus();
    }

    property bool shown: false
    property real contentScale: (shown && revealed) ? 1 : 0.95
    property real contentOpacity: (shown && revealed) ? 1 : 0
    Behavior on contentScale {
        animation: Appearance.animation.lockReveal.numberAnimation.createObject(this)
    }
    Behavior on contentOpacity {
        animation: Appearance.animation.lockReveal.numberAnimation.createObject(this)
    }

    Component.onCompleted: {
        forceFieldFocus();
        shown = true;
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

    // Kept visible while hidden so the password field holds focus and catches the first key
    ColumnLayout {
        id: userColumn
        anchors.centerIn: parent
        spacing: 16
        scale: root.contentScale
        opacity: root.contentOpacity

        Item {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: 128
            implicitHeight: 128

            MaterialSymbol {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready
                fill: 1
                text: "account_circle"
                iconSize: 128
                color: Appearance.colors.colOnLayer0
            }
            Image {
                id: avatar
                anchors.fill: parent
                visible: status === Image.Ready
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(width, height)
                source: Greeter.avatarPath
                asynchronous: true
                cache: false

                layer.enabled: true
                layer.effect: OpacityMask {
                    maskSource: Rectangle {
                        width: avatar.width
                        height: avatar.height
                        radius: width / 2
                    }
                }
            }
        }

        StyledText {
            Layout.alignment: Qt.AlignHCenter
            text: Greeter.displayName
            color: Appearance.colors.colOnLayer0
            style: Text.Raised
            styleColor: Appearance.colors.colShadow
            font {
                family: Appearance.font.family.title
                pixelSize: Appearance.font.pixelSize.title
                variableAxes: Appearance.font.variableAxes.title
            }
        }

        Toolbar {
            id: mainIsland
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8

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
                onAccepted: {
                    if (!root.revealed) {
                        root.context.reveal();
                        return;
                    }
                    root.context.tryLogin();
                }
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
                enabled: !root.context.inProgress && Greeter.currentSession !== null && root.revealed
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
    }

    Toolbar {
        id: bottomIsland
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 20
        }
        scale: root.contentScale
        opacity: root.contentOpacity
        visible: opacity > 0

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

        IconAndTextPair {
            readonly property var battery: UPower.displayDevice
            visible: battery.isLaptopBattery
            icon: battery.state === UPowerDeviceState.Charging ? "bolt" : "battery_android_full"
            text: Math.round(battery.percentage * 100)
        }

        IconToolbarButton {
            text: "power_settings_new"
            onClicked: {
                root.context.reveal();
                root.openSelector = null;
                root.sessionMenuOpen = true;
            }
        }
    }

    FadeLoader {
        anchors.fill: parent
        shown: root.sessionMenuOpen
        sourceComponent: Rectangle {
            color: ColorUtils.transparentize(Appearance.m3colors.m3background, Appearance.m3colors.darkmode ? 0.05 : 0.12)

            GreeterSessionMenu {
                anchors.fill: parent
                context: root.context
                onClosed: {
                    root.sessionMenuOpen = false;
                    root.forceFieldFocus();
                }
            }
        }
    }

    component Selector: ToolbarButton {
        id: selector
        required property string symbol
        required property var options
        required property string currentKey
        signal picked(string key)

        readonly property bool open: root.openSelector === selector
        horizontalPadding: 12
        onClicked: root.openSelector = open || options.length < 2 ? null : selector

        Behavior on implicitWidth {
            animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
        }

        contentItem: RowLayout {
            spacing: 6
            clip: true
            MaterialSymbol {
                fill: 1
                text: selector.symbol
                iconSize: Appearance.font.pixelSize.huge
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                text: selector.options.find(o => o.key === selector.currentKey)?.label ?? ""
                color: Appearance.colors.colOnSurfaceVariant
                animateChange: true
            }
            MaterialSymbol {
                visible: selector.options.length > 1
                text: "expand_less"
                rotation: selector.open ? 180 : 0
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSurfaceVariant
                Behavior on rotation {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }

        StyledRectangularShadow {
            parent: root
            z: 1
            target: popup
            visible: popup.visible
            opacity: popup.opacity
        }
        Rectangle {
            id: popup
            parent: root
            z: 2
            readonly property point origin: {
                bottomIsland.x; bottomIsland.y; bottomIsland.scale; selector.x; selector.width;
                return selector.mapToItem(root, selector.width / 2, 0);
            }
            x: Math.round(origin.x - width / 2)
            y: Math.round(origin.y - height - 18)
            opacity: selector.open ? 1 : 0
            visible: opacity > 0
            clip: true
            color: Appearance.m3colors.m3surfaceContainer
            radius: Appearance.rounding.normal
            implicitWidth: Math.max(popupColumn.implicitWidth, selector.width) + 16
            implicitHeight: selector.open ? popupColumn.implicitHeight + 16 : 0

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
            Behavior on implicitHeight {
                animation: Appearance.animation.elementResize.numberAnimation.createObject(this)
            }

            ColumnLayout {
                id: popupColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    bottom: parent.bottom
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
