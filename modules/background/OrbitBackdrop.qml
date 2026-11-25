import QtQuick
import QtQuick.Effects
import qs.config

// Behind the stars up in orbit: the world's sky, blurred and dimmed, its picture or its
// painted colours. Changing worlds, the new one loads behind the one shown and only fades in
// once it's ready, over it, so the sky never blinks on the way.
Item {
    id: root

    property string image: "" // the picture, or "" for a painted sky
    property color skyTop
    property color skyMid
    property color skyLow
    property real blur: Config.orbitBlur // 0 sharp, 1 as soft as it gets

    readonly property string key: image || `${skyTop}${skyMid}${skyLow}`
    property int shown: -1

    function load() {
        const slot = slots.itemAt(shown === 0 ? 1 : 0);
        slot?.take(image, skyTop, skyMid, skyLow);
    }

    onKeyChanged: Qt.callLater(load)
    Component.onCompleted: Qt.callLater(load)

    Repeater {
        id: slots

        model: 2

        Item {
            id: slot

            required property int index
            property string image: ""
            property color skyTop
            property color skyMid
            property color skyLow
            property string key: ""
            readonly property bool ready: key !== "" && (image === "" || picture.status === Image.Ready)

            function take(path, high, middle, bottom) {
                fadeIn.stop();
                slot.opacity = 0;
                slot.image = path;
                slot.skyTop = high;
                slot.skyMid = middle;
                slot.skyLow = bottom;
                slot.key = path || `${high}${middle}${bottom}`;
                // Already there (painted, or a picture held in memory): in at once
                if (slot.ready)
                    fadeIn.start();
            }

            anchors.fill: parent
            opacity: 0
            z: root.shown === index ? 0 : 1 // the one coming in goes over the one shown

            onReadyChanged: {
                if (ready && root.shown !== index && key === root.key)
                    fadeIn.start();
            }

            NumberAnimation {
                id: fadeIn

                target: slot
                property: "opacity"
                to: 1
                duration: root.shown < 0 ? 0 : 600
                easing.type: Easing.InOutQuad
                onFinished: {
                    const before = slots.itemAt(root.shown);
                    root.shown = slot.index;
                    if (before && before !== slot)
                        before.opacity = 0;
                }
            }

            // A painted sky is already smooth: its own bands
            Rectangle {
                anchors.fill: parent
                visible: slot.image === ""
                gradient: Gradient {
                    GradientStop { position: 0; color: slot.skyTop }
                    GradientStop { position: 0.62; color: slot.skyMid }
                    GradientStop { position: 0.92; color: slot.skyLow }
                }
            }

            // A picture: a small copy, cropped to the screen, blurred, stretched back up
            Item {
                anchors.fill: parent
                visible: slot.image !== ""

                Image {
                    id: picture

                    anchors.fill: parent
                    visible: false
                    asynchronous: true
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(640, Math.round(640 * root.height / Math.max(1, root.width)))
                    source: slot.image ? "file://" + encodeURI(slot.image).replace(/#/g, "%23") : ""
                }

                MultiEffect {
                    anchors.fill: parent
                    source: picture
                    blurEnabled: root.blur > 0
                    blur: root.blur
                    blurMax: 64
                    autoPaddingEnabled: false
                }
            }
        }
    }

    // Dimmed, so the stars and the planet read over it
    Rectangle {
        anchors.fill: parent
        z: 2
        color: "black"
        opacity: 0.58
    }
}
