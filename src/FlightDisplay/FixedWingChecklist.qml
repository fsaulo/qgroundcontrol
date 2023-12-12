/****************************************************************************
 *
 *   (c) 2009-2016 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick                      2.11
import QtQuick.Controls             2.4
import QtQml.Models                 2.1

import QGroundControl               1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controls      1.0
import QGroundControl.FlightDisplay 1.0
import QGroundControl.Vehicle       1.0

Item {
    property var model: listModel
    PreFlightCheckModel {
        id:     listModel
        PreFlightCheckGroup {
            name: qsTr("Albatross Initial Checks")

            PreFlightCheckButton {
                name:           qsTr("Airframe Check")
                manualText:     qsTr("The airframe is assembled and all screws are tightened accordingly")
            }

            PreFlightCheckButton {
                name:           qsTr("Propeller")
                manualText:     qsTr("The propeller is securely attached and not slipping. There is adequate clearance between the spinner and rear of the fuselage")
            }

            PreFlightCheckButton {
                name:           qsTr("Battery")
                manualText:     qsTr("The battery is sufficiently secure and unable to move")
            }

            PreFlightCheckButton {
                name:           qsTr("Wheels")
                manualText:     qsTr("All wheels are securely attached. The nose gear and wheels on the main landing gear axles rotate freely")
            }

            PreFlightCheckButton {
                name:           qsTr("Airspeed Pitot Tube")
                manualText:     qsTr("The Airspeed Pitot tube is fully extended")
            }

            PreFlightCheckButton {
                name:           qsTr("Airspeed Tubing")
                manualText:     qsTr("No kinks in the rubber tubing are present and the internal nose wheel linkage does not touch or catch on the rubber tubing when the nose gear is moved left to right")
            }

            PreFlightCheckButton {
                name:           qsTr("Internal Items Secure")
                manualText:     qsTr("All items are secured including internal batteries, applicable payloads, cameras, etc")
            }

            PreFlightCheckButton {
                name:           qsTr("Center of Gravity")
                manualText:     qsTr("The Center of Gravity is correctly set at 80-90mm")
            }

            PreFlightCheckButton {
                name:           qsTr("Canopy")
                manualText:     qsTr("The Canopy is affixed securely and the lock-spring is fully seated")
            }

            PreFlightCheckButton {
                name:           qsTr("Lidar")
                manualText:     qsTr("The Lidar Sensor is working properly and returning a reading larger than 0.00")
            }

            PreFlightCheckButton {
                name:           qsTr("Horizon Level")
                manualText:     qsTr("The Horizon was leveled taking into account any changes in standard wheel size")
            }

            PreFlightCheckButton {
                name:           qsTr("Safety")
                manualText:     qsTr("All Flight Team Participants are briefed on the operating procedures for this mission, including safety protocols")
            }


            PreFlightBatteryCheck {
                failurePercent:                 40
                allowFailurePercentOverride:    false
            }

            PreFlightSensorsHealthCheck {
            }

            PreFlightGPSCheck {
                failureSatCount:        9
                allowOverrideSatCount:  true
            }

            PreFlightRCCheck {
            }
        }

        PreFlightCheckGroup {
            name: qsTr("Please arm the vehicle here")

            PreFlightCheckButton {
                name:            qsTr("Actuators")
                manualText:      qsTr("Move all control surfaces to ensure they work properly")
            }

            PreFlightCheckButton {
                name:            qsTr("Motor")
                manualText:      qsTr("Propeller is clear of obstructions. A slight throttle up should equate to a clockwise motion")
            }

            PreFlightCheckButton {
                name:           qsTr("Mission")
                manualText:     qsTr("Please confirm mission is valid (waypoints valid, relative altitude used for planning, there are no terrain collisions).")
            }

            PreFlightSoundCheck {
            }
        }

        PreFlightCheckGroup {
            name: qsTr("Last preparations before launch")

            // Check list item group 2 - Final checks before launch
            PreFlightCheckButton {
                name:           qsTr("Taxi Test")
                manualText:     qsTr("A taxi test has been completed with correct ground tracking in the takeoff area")
            }

            PreFlightCheckButton {
                name:           qsTr("Camera Payload")
                manualText:     qsTr("Video stream present, camera is oriented in the correct direction for takeoff (with the lens shielded to either side) and recording is enabled if desired.")
            }

            PreFlightCheckButton {
                name:           qsTr("Wind & weather")
                manualText:     qsTr("OK for the setup and flight profile being flown and the mission is adjusted if necessary. Taking off into the wind.")
            }

            PreFlightCheckButton {
                name:           qsTr("Flight area")
                manualText:     qsTr("Takeoff area and path free of obstacles/people")
            }
        }
    }
}

