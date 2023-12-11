/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.12
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.12

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl.Palette       1.0

Rectangle {
    //id:         _root
   // width:      ScreenTools.defaultFontPixelWidth * 45
    //height:     mainLayout.height + (_margins * 2)
    //radius:     ScreenTools.defaultFontPixelWidth / 2
    //color:      qgcPal.window
    //visible:    false
    id:                     _root
    Layout.minimumWidth:    mainLayout.width + (_margins * 2)
    Layout.preferredHeight: mainLayout.height + (_margins * 2)
    radius:                 ScreenTools.defaultFontPixelWidth / 2
    color:                  qgcPal.windowShadeLight
    visible:                false //AA set to true when testing only. persists slide box


    property var    guidedController
    property var    guidedValueSlider
    property string title                                       // Currently unused
    property alias  message:            messageText.text
    property int    action
    property var    actionData
    property bool   hideTrigger:        false
    property var    mapIndicator
    property alias  optionText:         optionCheckBox.text
    property alias  optionChecked:      optionCheckBox.checked

    property real _margins:         ScreenTools.defaultFontPixelWidth / 2
    property bool _emergencyAction: action === guidedController.actionEmergencyStop

    Component.onCompleted: guidedController.confirmDialog = this

    onVisibleChanged: {
        if (visible) {
            slider.focus = true
        }
    }

    onHideTriggerChanged: {
        if (hideTrigger) {
            confirmCancelled()
        }
    }

    function show(immediate) {
        if (immediate) {
            visible = true
        } else {
            // We delay showing the confirmation for a small amount in order for any other state
            // changes to propogate through the system. This way only the final state shows up.
            visibleTimer.restart()
        }
    }

    function confirmCancelled() {
        guidedValueSlider.visible = false
        visible = false
        hideTrigger = false
        visibleTimer.stop()
        if (mapIndicator) {
            mapIndicator.actionCancelled()
            mapIndicator = undefined
        }
    }

    Timer {
        id:             visibleTimer
        interval:       1000
        repeat:         false
        onTriggered:    visible = true
    }

    QGCPalette { id: qgcPal }

    ColumnLayout {
        id:                         mainLayout
        //anchors.horizontalCenter:   parent.horizontalCenter
        //anchors.centerIn:           parent //AA added                     //AA location of slider
        //anchors.horizontalCenter:   parent.width / 2
        //anchors.verticalCenter:     parent.height / 2
        spacing:                    _margins

        Rectangle {
            width: 450                      //AA width of box where text is
            height:  30                     //AA height of box where text is
            //Layout.alignment: Qt.AlignHCenter
            //Layout.alignment: Qt.AlignCenter
            //Layout.leftMargin: -50
            //anchors.  horizontalCenter: parent.horizontalCenter
            //anchors.horizontalCenterOffet: -100                  //AA to get sentered
            Layout.leftMargin: -60                                  //AA to get sentered
            //radius: 30
            //color:      (qgcPal.globalTheme === QGCPalette.Light ? Qt.rgba(1,1,1,0.5) : Qt.rgba(1,1,1,0.5)) //AA controls the background color of where the text goes above the slider
            //color:       Qt.rgba(9,9,9,.55)                                   //AA color of background slider - matches side telem at this color
            //color:      (qgcPal.globalTheme === QGCPalette.Light ? "white" : "white") //AA controls the background color of where the text goes above the slider
            color:         "transparent"
            //z:   QGroundControl.zOrderVehicles
            //z: QGroundControl.zOrderWaypointLines



        QGCLabel {
            id:                     messageText
            Layout.fillWidth:       true
            //Layout.alignment: Qt.AlignVCenter
            font.bold:              true                            //AA added bold
            font.pointSize:         ScreenTools.mediumFontPointSize //AA Increases font size
            anchors.horizontalCenter: parent.horizontalCenter       //AA centers text horizontally
            //Layout.alignment:       parent.horizontalCenter
            //horizontalAlignment:    Text.AlignHCenter
            //verticalAlignment:       Text.AlignVCenter
            //Layout.alignment:       parent.verticalCenter
            anchors.verticalCenter: parent.verticalCenter           //AA centers text verically
            Layout.topMargin: -50          //AA to get centered
            wrapMode:               Text.WordWrap
            //color: "black" //AA controls text color above slider
            color:      (qgcPal.globalTheme === QGCPalette.Light ? "black" : "black") //AA controls text color above slider

            Rectangle {
                width: Math.max(messageText.width * 1.2, 420)
                height: messageText.height + mainLayout.height
                //color: "red"
                color:  Qt.rgba(9,9,9,.55)
                radius: 30
                anchors.horizontalCenter: parent.horizontalCenter
                z: _fullItemZorder - 1

            }

        }

        QGCCheckBox {
            id:                 optionCheckBox
            Layout.alignment:   Qt.AlignHCenter
            text:               ""
            visible:            text !== ""
        }

        RowLayout {
            //Layout.alignment:       Qt.AlignHCenter
            spacing:                ScreenTools.defaultFontPixelWidth

            SliderSwitch {
                id:                 slider
                confirmText:        ScreenTools.isMobile ? qsTr("Slide to confirm") : qsTr("Slide or hold spacebar")
                //Layout.fillWidth:   true
		 Layout.minimumWidth:    Math.max(implicitWidth, ScreenTools.defaultFontPixelWidth * 30)

                onAccept: {
                    _root.visible = false
                    var sliderOutputValue = 0
                    if (guidedValueSlider.visible) {
                        sliderOutputValue = guidedValueSlider.getOutputValue()
                        guidedValueSlider.visible = false
                    }
                    hideTrigger = false
                    guidedController.executeAction(_root.action, _root.actionData, sliderOutputValue, _root.optionChecked)
                    if (mapIndicator) {
                        mapIndicator.actionConfirmed()
                        mapIndicator = undefined
                    }
                }
            }

            Rectangle {
                height: slider.height * 0.75
                width:  height
                radius: height / 2
                color:  qgcPal.primaryButton

                QGCColoredImage {
                    anchors.margins:    parent.height / 4
                    anchors.fill:       parent
                    source:             "/res/XDelete.svg"
                    fillMode:           Image.PreserveAspectFit
                    color:              qgcPal.text
                }

                QGCMouseArea {
                    fillItem:   parent
                    onClicked:  confirmCancelled()
                }
            }
        }
    }
}

}
