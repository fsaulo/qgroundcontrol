/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.11
import QtQuick.Controls             2.4
import QtLocation                   5.3
import QtPositioning                5.3
import QtQuick.Dialogs              1.2
import QtQuick.Layouts              1.11
import QtQuick.Window 2.0

import QGroundControl               1.0
import QGroundControl.Controllers   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.FlightMap     1.0
import QGroundControl.Palette       1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Vehicle       1.0

FlightMap {
    id:                         _root
    allowGCSLocationCenter:     true
    allowVehicleLocationCenter: !_keepVehicleCentered
    planView:                   false
    zoomLevel:                  QGroundControl.flightMapZoom
    center:                     QGroundControl.flightMapPosition

    property Item pipState: _pipState
    QGCPipState {
        id:         _pipState
        pipOverlay: _pipOverlay
        isDark:     _isFullWindowItemDark
    }

    property var    rightPanelWidth
    property var    planMasterController
    property bool   pipMode:                    false   // true: map is shown in a small pip mode
    property var    toolInsets                          // Insets for the center viewport area

    property var    _activeVehicle:             QGroundControl.multiVehicleManager.activeVehicle
    property var    _planMasterController:      planMasterController
    property var    _geoFenceController:        planMasterController.geoFenceController
    property var    _rallyPointController:      planMasterController.rallyPointController
    property var    _activeVehicleCoordinate:   _activeVehicle ? _activeVehicle.coordinate : QtPositioning.coordinate()
    property var    _activeVehicleCoordinateGps1: _activeVehicle ? _activeVehicle.coordinateGps1 : QtPositioning.coordinate()
    property var    _activeVehicleCoordinateGps2: _activeVehicle ? _activeVehicle.coordinateGps2 : QtPositioning.coordinate()
    property real   _toolButtonTopMargin:       parent.height - mainWindow.height + (ScreenTools.defaultFontPixelHeight / 2)
    property real   _toolsMargin:               ScreenTools.defaultFontPixelWidth * 0.75
    property var    _flyViewSettings:           QGroundControl.settingsManager.flyViewSettings
    property bool   _keepMapCenteredOnVehicle:  _flyViewSettings.keepMapCenteredOnVehicle.rawValue

    property bool   _disableVehicleTracking:    false
    property bool   _keepVehicleCentered:       pipMode ? true : false
    property bool   _saveZoomLevelSetting:      true

    function _adjustMapZoomForPipMode() {
        _saveZoomLevelSetting = false
        if (pipMode) {
            if (QGroundControl.flightMapZoom > 3) {
                zoomLevel = QGroundControl.flightMapZoom - 3
            }
        } else {
            zoomLevel = QGroundControl.flightMapZoom
        }
        _saveZoomLevelSetting = true
    }

    onPipModeChanged: _adjustMapZoomForPipMode()

    onVisibleChanged: {
        if (visible) {
            // Synchronize center position with Plan View
            center = QGroundControl.flightMapPosition
        }
    }

    onZoomLevelChanged: {
        if (_saveZoomLevelSetting) {
            QGroundControl.flightMapZoom = zoomLevel
        }
    }
    onCenterChanged: {
        QGroundControl.flightMapPosition = center
    }

    // We track whether the user has panned or not to correctly handle automatic map positioning
    Connections {
        target: gesture

        function onPanStarted() {       _disableVehicleTracking = true }
        function onFlickStarted() {     _disableVehicleTracking = true }
        function onPanFinished() {      panRecenterTimer.restart() }
        function onFlickFinished() {    panRecenterTimer.restart() }
    }

    function pointInRect(point, rect) {
        return point.x > rect.x &&
                point.x < rect.x + rect.width &&
                point.y > rect.y &&
                point.y < rect.y + rect.height;
    }

    property real _animatedLatitudeStart
    property real _animatedLatitudeStop
    property real _animatedLongitudeStart
    property real _animatedLongitudeStop
    property real animatedLatitude
    property real animatedLongitude

    onAnimatedLatitudeChanged: _root.center = QtPositioning.coordinate(animatedLatitude, animatedLongitude)
    onAnimatedLongitudeChanged: _root.center = QtPositioning.coordinate(animatedLatitude, animatedLongitude)

    NumberAnimation on animatedLatitude { id: animateLat; from: _animatedLatitudeStart; to: _animatedLatitudeStop; duration: 1000 }
    NumberAnimation on animatedLongitude { id: animateLong; from: _animatedLongitudeStart; to: _animatedLongitudeStop; duration: 1000 }

    function animatedMapRecenter(fromCoord, toCoord) {
        _animatedLatitudeStart = fromCoord.latitude
        _animatedLongitudeStart = fromCoord.longitude
        _animatedLatitudeStop = toCoord.latitude
        _animatedLongitudeStop = toCoord.longitude
        animateLat.start()
        animateLong.start()
    }

    // returns the rectangle formed by the four center insets
    // used for checking if vehicle is under ui, and as a target for recentering the view
    function _insetCenterRect() {
        return Qt.rect(toolInsets.leftEdgeCenterInset,
                       toolInsets.topEdgeCenterInset,
                       _root.width - toolInsets.leftEdgeCenterInset - toolInsets.rightEdgeCenterInset,
                       _root.height - toolInsets.topEdgeCenterInset - toolInsets.bottomEdgeCenterInset)
    }

    // returns the four rectangles formed by the 8 corner insets
    // used for detecting if the vehicle has flown under the instrument panel, virtual joystick etc
    function _insetCornerRects() {
        var rects = {
        "topleft":      Qt.rect(0,0,
                               toolInsets.leftEdgeTopInset,
                               toolInsets.topEdgeLeftInset),
        "topright":     Qt.rect(_root.width-toolInsets.rightEdgeTopInset,0,
                               toolInsets.rightEdgeTopInset,
                               toolInsets.topEdgeRightInset),
        "bottomleft":   Qt.rect(0,_root.height-toolInsets.bottomEdgeLeftInset,
                               toolInsets.leftEdgeBottomInset,
                               toolInsets.bottomEdgeLeftInset),
        "bottomright":  Qt.rect(_root.width-toolInsets.rightEdgeBottomInset,_root.height-toolInsets.bottomEdgeRightInset,
                               toolInsets.rightEdgeBottomInset,
                               toolInsets.bottomEdgeRightInset)}
        return rects
    }

    function recenterNeeded() {
        var vehiclePoint = _root.fromCoordinate(_activeVehicleCoordinate, false /* clipToViewport */)
        var centerRect = _insetCenterRect()
        //return !pointInRect(vehiclePoint,insetRect)

        // If we are outside the center inset rectangle, recenter
        if(!pointInRect(vehiclePoint, centerRect)){
            return true
        }

        // if we are inside the center inset rectangle
        // then additionally check if we are underneath one of the corner inset rectangles
        var cornerRects = _insetCornerRects()
        if(pointInRect(vehiclePoint, cornerRects["topleft"])){
            return true
        } else if(pointInRect(vehiclePoint, cornerRects["topright"])){
            return true
        } else if(pointInRect(vehiclePoint, cornerRects["bottomleft"])){
            return true
        } else if(pointInRect(vehiclePoint, cornerRects["bottomright"])){
            return true
        }

        // if we are inside the center inset rectangle, and not under any corner elements
        return false
    }

    function updateMapToVehiclePosition() {
        if (animateLat.running || animateLong.running) {
            return
        }
        // We let FlightMap handle first vehicle position
        if (!_keepMapCenteredOnVehicle && firstVehiclePositionReceived && _activeVehicleCoordinate.isValid && !_disableVehicleTracking) {
            if (_keepVehicleCentered) {
                _root.center = _activeVehicleCoordinate
            } else {
                if (firstVehiclePositionReceived && recenterNeeded()) {
                    // Move the map such that the vehicle is centered within the inset area
                    var vehiclePoint = _root.fromCoordinate(_activeVehicleCoordinate, false /* clipToViewport */)
                    var centerInsetRect = _insetCenterRect()
                    var centerInsetPoint = Qt.point(centerInsetRect.x + centerInsetRect.width / 2, centerInsetRect.y + centerInsetRect.height / 2)
                    var centerOffset = Qt.point((_root.width / 2) - centerInsetPoint.x, (_root.height / 2) - centerInsetPoint.y)
                    var vehicleOffsetPoint = Qt.point(vehiclePoint.x + centerOffset.x, vehiclePoint.y + centerOffset.y)
                    var vehicleOffsetCoord = _root.toCoordinate(vehicleOffsetPoint, false /* clipToViewport */)
                    animatedMapRecenter(_root.center, vehicleOffsetCoord)
                }
            }
        }
    }

    on_ActiveVehicleCoordinateChanged: {
        if (_keepMapCenteredOnVehicle && _activeVehicleCoordinate.isValid && !_disableVehicleTracking) {
            _root.center = _activeVehicleCoordinate
        }
    }



    Timer {
        id:         panRecenterTimer
        interval:   10000
        running:    false
        onTriggered: {
            _disableVehicleTracking = false
            updateMapToVehiclePosition()
        }
    }

    Timer {
        interval:       500
        running:        true
        repeat:         true
        onTriggered:    updateMapToVehiclePosition()
    }


    QGCMapPalette { id: mapPal; lightColors: isSatelliteMap }

    Connections {
        target:                 _missionController
        ignoreUnknownSignals:   true
        function onNewItemsFromVehicle() {
            var visualItems = _missionController.visualItems
            if (visualItems && visualItems.count !== 1) {
                mapFitFunctions.fitMapViewportToMissionItems()
                firstVehiclePositionReceived = true
            }
        }
    }

    MapFitFunctions {
        id:                         mapFitFunctions // The name for this id cannot be changed without breaking references outside of this code. Beware!
        map:                        _root
        usePlannedHomePosition:     false
        planMasterController:       _planMasterController
    }

    ObstacleDistanceOverlayMap {
        id: obstacleDistance
        showText: !pipMode
    }

    // Add trajectory lines to the map
    MapPolyline {
        id:         trajectoryPolyline
        line.width: 3
        line.color: "red"
        z:          QGroundControl.zOrderTrajectoryLines
        visible:    !pipMode

        Connections {
            target:                 QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) {
                trajectoryPolyline.path = _activeVehicle ? _activeVehicle.trajectoryPoints.list() : []
            }
        }

        Connections {
            target:                 _activeVehicle ? _activeVehicle.trajectoryPoints : null
            onPointAdded:           trajectoryPolyline.addCoordinate(coordinate)
            onUpdateLastPoint:      trajectoryPolyline.replaceCoordinate(trajectoryPolyline.pathLength() - 1, coordinate)
            onPointsCleared:        trajectoryPolyline.path = []
        }
    }

    // Add Gps1 trajectory lines to the map
       MapPolyline {
           id:         trajectoryGps1Polyline
           line.width: 3
           line.color: "green"
           z:          QGroundControl.zOrderTrajectoryLines
           visible:    !pipMode

           Connections {
               target:                 QGroundControl.multiVehicleManager
               function onActiveVehicleChanged(activeVehicle) {
                   trajectoryGps1Polyline.path = _activeVehicle ? _activeVehicle.trajectoryPoints.listGps1() : []
               }
           }

           Connections {
               target:                 _activeVehicle ? _activeVehicle.trajectoryPoints : null
               onPointAdded1:           trajectoryGps1Polyline.addCoordinate(_activeVehicleCoordinateGps1)
               onUpdateLastPoint1:      trajectoryGps1Polyline.replaceCoordinate(trajectoryGps1Polyline.pathLength() - 1, _activeVehicleCoordinateGps1)
               onPointsCleared:        trajectoryGps1Polyline.path = []
           }
       }

       // Add Gps2 trajectory lines to the map
       MapPolyline {
           id:         trajectoryGps2Polyline
           line.width: 3
           line.color: "blue"
           z:          QGroundControl.zOrderTrajectoryLines
           visible:    !pipMode

           Connections {
               target:                 QGroundControl.multiVehicleManager
               function onActiveVehicleChanged(activeVehicle) {
                   trajectoryGps2Polyline.path = _activeVehicle ? _activeVehicle.trajectoryPoints.listGps2() : []
               }
           }

           Connections {
               target:                 _activeVehicle ? _activeVehicle.trajectoryPoints : null
               onPointAdded2:           trajectoryGps2Polyline.addCoordinate(_activeVehicleCoordinateGps2)
               onUpdateLastPoint2:      trajectoryGps2Polyline.replaceCoordinate(trajectoryGps2Polyline.pathLength() - 1, _activeVehicleCoordinateGps2)
               onPointsCleared:        trajectoryGps2Polyline.path = []
           }
       }

    // Add the vehicles to the map
    MapItemView {
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: VehicleMapItem {
            vehicle:        object
            coordinate:     object.coordinate
            map:            _root
            size:           pipMode ? ScreenTools.defaultFontPixelHeight : ScreenTools.defaultFontPixelHeight * 6 // AA added Controls vehicle size when planning (*3 is normal)
            z:              QGroundControl.zOrderVehicles
        }
    }
    // Add distance sensor view
    MapItemView{
        model: QGroundControl.multiVehicleManager.vehicles
        delegate: ProximityRadarMapView {
            vehicle:        object
            coordinate:     object.coordinate
            map:            _root
            z:              QGroundControl.zOrderVehicles
        }
    }
    // Add ADSB vehicles to the map
    MapItemView {
        model: QGroundControl.adsbVehicleManager.adsbVehicles
        delegate: VehicleMapItem {
            coordinate:     object.coordinate
            altitude:       object.altitude
            callsign:       object.callsign
            heading:        object.heading
            alert:          object.alert
            map:            _root
            size:           pipMode ? ScreenTools.defaultFontPixelHeight : ScreenTools.defaultFontPixelHeight * 2.5
            z:              QGroundControl.zOrderVehicles
        }
    }

    // Add the items associated with each vehicles flight plan to the map
    Repeater {
        model: QGroundControl.multiVehicleManager.vehicles

        PlanMapItems {
            map:                    _root
            largeMapView:           !pipMode
            planMasterController:   masterController
            vehicle:                _vehicle

            property var _vehicle: object

            PlanMasterController {
                id: masterController
                Component.onCompleted: startStaticActiveVehicle(object)
            }
        }
    }

    MapItemView {
        model: pipMode ? undefined : _missionController.directionArrows

        delegate: MapLineArrow {
            fromCoord:      object ? object.coordinate1 : undefined
            toCoord:        object ? object.coordinate2 : undefined
            arrowPosition:  2
            z:              QGroundControl.zOrderWaypointLines
        }
    }

    readonly property string sysMode: "SysMode"
    readonly property string gpsJam: "GpsJam"
    readonly property int gpsJammingDisabled: 0
    readonly property int gpsJammingEnabled: 1
    readonly property int sysModeReady: 1
    readonly property int sysModeSensorError: 2
    readonly property int sysModeVPSError: 3
    readonly property int sysModeRunning: 4

    function handleGpsJam(value){
            if(_root.gpsJammingDisabled === value){
                vermeerGPSJammingState.text = "OFF"
                vermeerGPSJammingState.color = vermeerStatusUI.negativeColour
            } else if (_root.gpsJammingEnabled === value){
                vermeerGPSJammingState.text = "ON"
                vermeerGPSJammingState.color = vermeerStatusUI.positiveColour
            } else {
                var errorMsg = "Invalid Gps Jamming State: " + value
                console.log(errorMsg)
            }
        }

        function handleSysModeMsg(value){
            if(_root.sysModeReady === value){
                vermeerStatusState.text = "Ready"
                vermeerStatusCircle.color = vermeerStatusUI.positiveColour
            } else if (_root.sysModeSensorError === value){
                vermeerStatusState.text = "Sensor\nError"
                vermeerStatusCircle.color = vermeerStatusUI.negativeColour
            } else if (_root.sysModeVPSError === value){
                vermeerStatusState.text = "VPS\nError"
                vermeerStatusCircle.color = vermeerStatusUI.negativeColour
            } else if (_root.sysModeRunning === value){
                vermeerStatusState.text = "Running"
                vermeerStatusCircle.color = vermeerStatusUI.positiveColour
            } else {
                var errorMsg = "Invalid Sys Mode: " + value
                console.log(errorMsg)
            }
        }

        Connections {
            target: _activeVehicle ? _activeVehicle : null
            onUpdateVermeerStatus: {
                if(_root.sysMode === vermeerStatusName){
                    handleSysModeMsg(vermeerStatusValue)
                } else if (_root.gpsJam === vermeerStatusName) {
                    handleGpsJam(vermeerStatusValue)
                } else {
                    var errorMsg  = "Invalid Vermeer Status Name" + vermeerStatusName
                    console.log(errorMsg)
                }
            }
        }

        Rectangle {
            readonly property string positiveColour: "#56D663"
            readonly property string negativeColour: "#D6003F"

            id: vermeerStatusUI
            width: 180 + parent.width * 0.05
            height: 90
            color: "#101010"
            visible: true
            radius: 12
            //x:parent.width * 0.99 - vermeerStatusUI.width
            x:40
            y:parent.height * 0.99 - vermeerStatusUI.height - 10

            // Allow custom builds to add map items
            CustomMapItems {
                readonly property var legendBoxWidth:  370
                readonly property var legendBoxHeight: 180

                map:               _root
                largeMapView:      mainIsMap
                visible:           true
                x:                 vermeerStatusUI.width  * 0.50
                y:                 vermeerStatusUI.height * 0.10

                Rectangle {
                    id: vermeerGpsLegends
                    anchors.margins: _toolsMargin
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter

                    width:             legendBoxWidth
                    height:            legendBoxHeight
                    opacity:           0.6
                    radius:            3
                    color:             "black"

                    ColumnLayout {
                        spacing: 5
                        LegendWidget {
                            routeName: "EKF"
                            routeColor: "red"
                        }

                        LegendWidget {
                            routeName: "GPS1"
                            routeColor: "green"
                        }

                        LegendWidget {
                            routeName: "VPS"
                            routeColor: "blue"
                        }
                    }
                }
            }

            ColumnLayout {
                spacing: 10
                anchors.verticalCenter: parent.verticalCenter

                RowLayout {
                    spacing: 5
                    Layout.leftMargin: 10

                    Rectangle{
                        id: vermeerStatusCircle
                        width: 30
                        height: 30
                        visible: true
                        radius: width/2
                        color: vermeerStatusUI.negativeColour
                        anchors.left: vermeerStatusUI.left
                        anchors.top: vermeerStatusUI.top
                        anchors.leftMargin: 10
                        anchors.topMargin: 20
                    }

                    Text {
                        id: vermeerStatusState
                        text: qsTr("Offline")
                        color: "white"
                        anchors.left: vermeerStatusCircle.right
                        anchors.top: vermeerStatusUI.top
                        anchors.leftMargin: 10
                        anchors.topMargin: 20
                        font {
                            pointSize: 9
                            family: "Inter"
                            bold: true
                        }
                    }
                }

                RowLayout {
                    spacing: 5
                    Layout.leftMargin: 10

                    Text {
                        id: vermeerGPSJammingState
                        text: qsTr("OFF")
                        color: vermeerStatusUI.negativeColour
                        anchors.left: vermeerStatusUI.left
                        anchors.top: vermeerStatusState.bottom
                        anchors.leftMargin: 10
                        anchors.topMargin: 20
                        font {
                            pointSize: 9
                            family: "Inter"
                            bold: true
                        }
                    }

                    Text {
                        id: vermeerGPSJammingTittle
                        text: qsTr("GPS Jam")
                        color: "white"
                        anchors.left: vermeerGPSJammingState.right
                        anchors.top: vermeerStatusState.bottom
                        anchors.leftMargin: 10
                        anchors.topMargin: 20
                        font {
                            pointSize: 9
                            family: "Inter"
                            bold: true
                        }
                    }
                }
            }
    }



    GeoFenceMapVisuals {
        map:                    _root
        myGeoFenceController:   _geoFenceController
        interactive:            false
        planView:               false
        homePosition:           _activeVehicle && _activeVehicle.homePosition.isValid ? _activeVehicle.homePosition :  QtPositioning.coordinate()
    }

    // Rally points on map
    MapItemView {
        model: _rallyPointController.points

        delegate: MapQuickItem {
            id:             itemIndicator
            anchorPoint.x:  sourceItem.anchorPointX
            anchorPoint.y:  sourceItem.anchorPointY
            coordinate:     object.coordinate
            z:              QGroundControl.zOrderMapItems

            sourceItem: MissionItemIndexLabel {
                id:         itemIndexLabel
                label:      qsTr("R", "rally point map item label")
            }
        }
    }

    // Camera trigger points
    MapItemView {
        model: _activeVehicle ? _activeVehicle.cameraTriggerPoints : 0

        delegate: CameraTriggerIndicator {
            coordinate:     object.coordinate
            z:              QGroundControl.zOrderTopMost
        }
    }

    // GoTo Location visuals
    MapQuickItem {
        id:             gotoLocationItem
        visible:        false
        z:              QGroundControl.zOrderMapItems
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("Go here", "Go to location waypoint")
        }

        property bool inGotoFlightMode: _activeVehicle ? _activeVehicle.flightMode === _activeVehicle.gotoFlightMode : false

        onInGotoFlightModeChanged: {
            if (!inGotoFlightMode && gotoLocationItem.visible) {
                // Hide goto indicator when vehicle falls out of guided mode
                gotoLocationItem.visible = false
            }
        }

        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) {
                if (!activeVehicle) {
                    gotoLocationItem.visible = false
                }
            }
        }

        function show(coord) {
            gotoLocationItem.coordinate = coord
            gotoLocationItem.visible = true
        }

        function hide() {
            gotoLocationItem.visible = false
        }

        function actionConfirmed() {
            // We leave the indicator visible. The handling for onInGuidedModeChanged will hide it.
        }

        function actionCancelled() {
            hide()
        }
    }

    // Orbit editing visuals
    QGCMapCircleVisuals {
        id:             orbitMapCircle
        mapControl:     parent
        mapCircle:      _mapCircle
        visible:        false

        property alias center:              _mapCircle.center
        property alias clockwiseRotation:   _mapCircle.clockwiseRotation
        readonly property real defaultRadius: 30

        Connections {
            target: QGroundControl.multiVehicleManager
            function onActiveVehicleChanged(activeVehicle) {
                if (!activeVehicle) {
                    orbitMapCircle.visible = false
                }
            }
        }

        function show(coord) {
            _mapCircle.radius.rawValue = defaultRadius
            orbitMapCircle.center = coord
            orbitMapCircle.visible = true
        }

        function hide() {
            orbitMapCircle.visible = false
        }

        function actionConfirmed() {
            // Live orbit status is handled by telemetry so we hide here and telemetry will show again.
            hide()
        }

        function actionCancelled() {
            hide()
        }

        function radius() {
            return _mapCircle.radius.rawValue
        }

        Component.onCompleted: globals.guidedControllerFlyView.orbitMapCircle = orbitMapCircle

        QGCMapCircle {
            id:                 _mapCircle
            interactive:        true
            radius.rawValue:    30
            showRotation:       true
            clockwiseRotation:  true
        }
    }

    // ROI Location visuals
    MapQuickItem {
        id:             roiLocationItem
        visible:        _activeVehicle && _activeVehicle.isROIEnabled
        z:              QGroundControl.zOrderMapItems
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("ROI here", "Make this a Region Of Interest")
        }

        //-- Visibilty controlled by actual state
        function show(coord) {
            roiLocationItem.coordinate = coord
        }

        function hide() {
        }

        function actionConfirmed() {
        }

        function actionCancelled() {
        }
    }


    // Orbit telemetry visuals
    QGCMapCircleVisuals {
        id:             orbitTelemetryCircle
        mapControl:     parent
        mapCircle:      _activeVehicle ? _activeVehicle.orbitMapCircle : null
        visible:        _activeVehicle ? _activeVehicle.orbitActive : false
    }

    MapQuickItem {
        id:             orbitCenterIndicator
        anchorPoint.x:  sourceItem.anchorPointX
        anchorPoint.y:  sourceItem.anchorPointY
        coordinate:     _activeVehicle ? _activeVehicle.orbitMapCircle.center : QtPositioning.coordinate()
        visible:        orbitTelemetryCircle.visible

        sourceItem: MissionItemIndexLabel {
            checked:    true
            index:      -1
            label:      qsTr("Orbit", "Orbit waypoint")
        }
    }


    // Handle guided mode clicks
    MouseArea {
        anchors.fill: parent

        Popup {
            id: clickMenu
            modal: true

            property var coord

            function setCoordinates(mouseX, mouseY) {
                var newX = mouseX
                var newY = mouseY

                // Filtering coordinates
                if (newX + clickMenu.width > _root.width) {
                    newX = _root.width - clickMenu.width
                }
                if (newY + clickMenu.height > _root.height) {
                    newY = _root.height - clickMenu.height
                }

                // Set coordiantes
                x = newX
                y = newY
            }

            background: Rectangle {
                radius: ScreenTools.defaultFontPixelHeight * 0.5
                color: qgcPal.window
                border.color: qgcPal.text
            }

            ColumnLayout {
                id: mainLayout
                spacing: ScreenTools.defaultFontPixelWidth / 2

                QGCButton {
                    Layout.fillWidth: true
                    text: "Go to location"
                    visible: globals.guidedControllerFlyView.showGotoLocation
                    onClicked: {
                        if (clickMenu.opened) {
                            clickMenu.close()
                        }
                        gotoLocationItem.show(clickMenu.coord)
                        globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionGoto, clickMenu.coord, gotoLocationItem)
                    }
                }

                QGCButton {
                    Layout.fillWidth: true
                    text: "Orbit at location"
                    visible: globals.guidedControllerFlyView.showOrbit
                    onClicked: {
                        if (clickMenu.opened) {
                            clickMenu.close()
                        }
                        orbitMapCircle.show(clickMenu.coord)
                        globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionOrbit, clickMenu.coord, orbitMapCircle)
                    }
                }

                QGCButton {
                    Layout.fillWidth: true
                    text: "ROI at location"
                    visible: globals.guidedControllerFlyView.showROI
                    onClicked: {
                        if (clickMenu.opened) {
                            clickMenu.close()
                        }
                        roiLocationItem.show(clickMenu.coord)
                        globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionROI, clickMenu.coord, roiLocationItem)
                    }
                }

                QGCButton {
                    Layout.fillWidth: true
                    text: "Set home here"
                    visible: globals.guidedControllerFlyView.showSetHome
                    onClicked: {
                        if (clickMenu.opened) {
                            clickMenu.close()
                        }
                        globals.guidedControllerFlyView.confirmAction(globals.guidedControllerFlyView.actionSetHome, clickMenu.coord)
                    }
                }
            }
        }

        onClicked: {
            if (!globals.guidedControllerFlyView.guidedUIVisible && (globals.guidedControllerFlyView.showGotoLocation || globals.guidedControllerFlyView.showOrbit || globals.guidedControllerFlyView.showROI || globals.guidedControllerFlyView.showSetHome)) {
                orbitMapCircle.hide()
                gotoLocationItem.hide()
                var clickCoord = _root.toCoordinate(Qt.point(mouse.x, mouse.y), false /* clipToViewPort */)
                clickMenu.coord = clickCoord
                clickMenu.setCoordinates(mouse.x, mouse.y)
                clickMenu.open()
            }
        }
    }

    MapScale {
        id:                 mapScale
        anchors.margins:    _toolsMargin
        anchors.left:       parent.left
        anchors.top:        parent.top
        mapControl:         _root
        buttonsOnLeft:      false
        visible:            !ScreenTools.isTinyScreen && QGroundControl.corePlugin.options.flyView.showMapScale && mapControl.pipState.state === mapControl.pipState.windowState

        property real centerInset: visible ? parent.height - y : 0
    }

}
