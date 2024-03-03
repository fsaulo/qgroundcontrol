import QtQuick          2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts  1.12

import QGroundControl             1.0
import QGroundControl.ScreenTools 1.0

RowLayout {
    property          string routeName:  ""
    property          var    routeColor

    readonly property real   _rectWidth: ScreenTools.defaultFontPixelWidth * 2

    spacing: 6
    id: legendWidget

    Rectangle {
        width:        _rectWidth
        height:       _rectWidth
        color:        routeColor
        border.color: "black"
        border.width: 2
    }

    Text {
        text:      routeName
        font.bold: true
        color:     "white"
    }
}

