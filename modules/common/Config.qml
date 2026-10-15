pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

Singleton {
    id: root
    property alias options: configOptionsJsonAdapter
    property bool ready: false

    FileView {
        path: Greeter.configPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.ready = true
        onLoadFailed: root.ready = true

        JsonAdapter {
            id: configOptionsJsonAdapter

            property JsonObject appearance: JsonObject {
                property bool extraBackgroundTint: true
                property JsonObject fonts: JsonObject {
                    property string main: "Rubik"
                    property string numbers: "Rubik"
                    property string title: "Rubik"
                    property string iconNerd: "JetBrains Mono NF"
                    property string monospace: "JetBrains Mono NF"
                    property string reading: "Readex Pro"
                    property string expressive: "Space Grotesk"
                }
                property JsonObject transparency: JsonObject {
                    property bool enable: false
                    property bool automatic: true
                    property real backgroundTransparency: 0.11
                    property real contentTransparency: 0.57
                }
            }

            property JsonObject background: JsonObject {
                property JsonObject widgets: JsonObject {
                    property JsonObject clock: JsonObject {
                        property bool enable: true
                        property string style: "cookie"
                        property string styleLocked: "cookie"
                        property JsonObject cookie: JsonObject {
                            property int sides: 14
                            property string dialNumberStyle: "full"
                            property string hourHandStyle: "fill"
                            property string minuteHandStyle: "medium"
                            property string secondHandStyle: "dot"
                            property string dateStyle: "bubble"
                            property bool timeIndicators: true
                            property bool hourMarks: false
                            property bool dateInClock: true
                            property bool constantlyRotate: false
                            property bool useSineCookie: false
                        }
                        property JsonObject digital: JsonObject {
                            property bool adaptiveAlignment: true
                            property bool showDate: true
                            property bool animateChange: true
                            property bool vertical: false
                            property string color: ""
                            property JsonObject font: JsonObject {
                                property string family: "Rubik"
                                property real weight: 350
                                property real width: 100
                                property real size: 90
                                property real roundness: 0
                            }
                        }
                        property JsonObject quote: JsonObject {
                            property bool enable: false
                            property string text: ""
                        }
                    }
                }
                property string wallpaperPath: ""
                property string thumbnailPath: ""
            }

            property JsonObject lock: JsonObject {
                property JsonObject blur: JsonObject {
                    property bool enable: true
                    property real radius: 100
                    property real extraZoom: 1.1
                }
                property bool materialShapeChars: true
            }

            property JsonObject time: JsonObject {
                property string format: "hh:mm"
                property string shortDateFormat: "dd/MM"
                property string dateWithYearFormat: "dd/MM/yyyy"
                property string dateFormat: "ddd, dd/MM"
                property bool secondPrecision: false
            }
        }
    }
}
