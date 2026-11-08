import QtQuick

// Counts the frames of one move while it plays, and logs how smooth it was: the average,
// and the worst frame, which is the one you actually see stutter.
FrameAnimation {
    id: root

    required property string name
    property real startedAt: 0
    property real worst: 0

    onTriggered: worst = Math.max(worst, frameTime)
    onRunningChanged: {
        if (running) {
            startedAt = Date.now();
            worst = 0;
        } else if (currentFrame > 1) {
            const spent = Date.now() - startedAt;
            console.info(`ETEA ${name}: ${currentFrame} frames in ${spent} ms, ${Math.round(currentFrame * 1000 / spent)} fps, worst ${Math.round(worst * 1000)} ms`);
        }
    }
}
