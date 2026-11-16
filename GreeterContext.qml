import QtQuick
import Quickshell
import Quickshell.Services.Greetd
import qs.services
import qs.modules.common

Scope {
    id: root

    signal shouldReFocus()
    signal failed()

    property string currentText: ""
    property bool inProgress: false
    property bool showFailure: false
    property string message: ""
    property bool answerNextPrompt: false
    property bool awaitingResponse: false

    function clearText() {
        root.currentText = "";
    }

    property bool revealed: false

    function resetClearTimer() {
        root.reveal();
    }

    function reveal() {
        root.revealed = true;
        inactivityTimer.restart();
    }

    function reset() {
        if (Greetd.state !== GreetdState.Inactive)
            Greetd.cancelSession();
        root.clearText();
        root.inProgress = false;
        root.answerNextPrompt = false;
        root.awaitingResponse = false;
        root.message = "";
    }

    function fail(message) {
        root.reset();
        root.message = message;
        root.showFailure = true;
        root.reveal();
        root.failed();
    }

    function tryLogin() {
        if (root.inProgress || !Greeter.currentSession)
            return;
        if (Greeter.devMode) {
            Qt.quit();
            return;
        }
        root.inProgress = true;
        if (root.awaitingResponse) {
            root.awaitingResponse = false;
            Greetd.respond(root.currentText);
            return;
        }
        root.answerNextPrompt = true;
        Greetd.createSession(Greeter.user);
    }

    Timer {
        id: inactivityTimer
        interval: Config.options.lock.revealTimeout * 1000
        onTriggered: {
            if (root.inProgress || root.awaitingResponse) {
                restart();
                return;
            }
            root.clearText();
            root.revealed = false;
        }
    }

    onCurrentTextChanged: {
        if (currentText.length === 0) return;
        showFailure = false;
        root.reveal();
    }

    Connections {
        target: Greeter
        function onUserChanged() {
            root.reset();
        }
    }

    Connections {
        target: Greetd

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            if (!responseRequired) {
                root.message = message;
                return;
            }
            if (root.answerNextPrompt) {
                root.answerNextPrompt = false;
                Greetd.respond(root.currentText);
                return;
            }
            root.clearText();
            root.message = message;
            root.awaitingResponse = true;
            root.inProgress = false;
            root.reveal();
            root.shouldReFocus();
        }

        function onReadyToLaunch() {
            Greeter.saveLast();
            Greetd.launch(Greeter.launchCommand(), Greeter.launchEnvironment());
        }

        function onAuthFailure(message) {
            root.fail("");
        }

        function onError(error) {
            root.fail(error);
        }
    }
}
