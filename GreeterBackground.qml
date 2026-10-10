import QtQuick
import Qt5Compat.GraphicalEffects
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import qs.modules.ii.background.widgets.clock

Item {
    id: root
    readonly property var clockConfig: Config.options.background.widgets.clock
    readonly property var blurConfig: Config.options.lock.blur
    readonly property string wallpaperPath: {
        const bg = Config.options.background;
        return /\.(mp4|webm|mkv|avi|mov)$/i.test(bg.wallpaperPath) ? bg.thumbnailPath : bg.wallpaperPath;
    }
    clip: true

    Rectangle {
        anchors.fill: parent
        color: Appearance.colors.colLayer0
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        source: root.wallpaperPath
        asynchronous: true
        cache: false
    }

    Loader {
        active: root.blurConfig.enable
        anchors.fill: wallpaper
        scale: root.blurConfig.extraZoom
        sourceComponent: GaussianBlur {
            source: wallpaper
            radius: root.blurConfig.radius
            samples: radius * 2 + 1

            Rectangle {
                anchors.fill: parent
                color: ColorUtils.transparentize(Appearance.colors.colLayer0, 0.7)
            }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 10
        visible: root.clockConfig.enable

        FadeLoader {
            anchors.horizontalCenter: parent.horizontalCenter
            shown: root.clockConfig.styleLocked === "cookie"
            fade: false
            sourceComponent: Column {
                spacing: 10
                CookieClock {
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                FadeLoader {
                    anchors.horizontalCenter: parent.horizontalCenter
                    shown: root.clockConfig.quote.enable && root.clockConfig.quote.text !== ""
                    sourceComponent: CookieQuote {}
                }
            }
        }

        FadeLoader {
            anchors.horizontalCenter: parent.horizontalCenter
            shown: root.clockConfig.styleLocked === "digital"
            fade: false
            sourceComponent: DigitalClock {
                colText: root.clockConfig.digital.color || Appearance.colors.colOnLayer0
            }
        }
    }
}
