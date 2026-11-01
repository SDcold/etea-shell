import QtQuick
import qs.config

// Things settle in from the top down, a beat apart, instead of all landing at once.
SequentialAnimation {
    id: root

    required property Item item
    property int wait: 0

    function begin() {
        wait = Math.min(240, Math.max(0, item.mapToItem(null, 0, 0).y * 0.32));
        start();
    }

    PauseAnimation {
        duration: root.wait
    }
    ParallelAnimation {
        NumberAnimation {
            target: root.item
            property: "opacity"
            to: 1
            duration: Theme.normal
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: root.item
            property: "scale"
            from: 0.9
            to: 1
            duration: Theme.normal + 120
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.expressive
        }
    }

    Component.onCompleted: {
        item.opacity = 0;
        Qt.callLater(begin);
    }
}
