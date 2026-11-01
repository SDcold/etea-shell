import QtQuick
import QtQuick.Effects
import qs.config

// Text sitting right on the sky, with a soft glow to lift it off the background.
Row {
    spacing: 18
    height: Theme.barHeight
    layer.enabled: true
    layer.effect: MultiEffect {
        autoPaddingEnabled: true
        shadowEnabled: true
        shadowColor: Theme.textGlow
        shadowOpacity: 0.55
        shadowBlur: 1
        blurMax: 32
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
    }
}
