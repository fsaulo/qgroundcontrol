/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "TrajectoryPoints.h"
#include "Vehicle.h"

TrajectoryPoints::TrajectoryPoints(Vehicle* vehicle, QObject* parent)
    : QObject       (parent)
    , _vehicle      (vehicle)
    , _lastAzimuth  (qQNaN())
{
}

void TrajectoryPoints::_vehicleCoordinateChanged(QGeoCoordinate coordinate)
{
    // The goal of this algorithm is to limit the number of trajectory points whic represent the vehicle path.
    // Fewer points means higher performance of map display.

    if (_lastPoint.isValid()) {
        double distance = _lastPoint.distanceTo(coordinate);
        if (distance > _distanceTolerance) {
            //-- Update flight distance
            _vehicle->updateFlightDistance(distance);
            // Vehicle has moved far enough from previous point for an update
            double newAzimuth = _lastPoint.azimuthTo(coordinate);
            if (qIsNaN(_lastAzimuth) || qAbs(newAzimuth - _lastAzimuth) > _azimuthTolerance) {
                // The new position IS NOT colinear with the last segment. Append the new position to the list.
                _lastAzimuth = _lastPoint.azimuthTo(coordinate);
                _lastPoint = coordinate;
                _points.append(QVariant::fromValue(coordinate));
                emit pointAdded(coordinate);
            } else {
                // The new position IS colinear with the last segment. Don't add a new point, just update
                // the last point to be the new position.
                _lastPoint = coordinate;
                _points[_points.count() - 1] = QVariant::fromValue(coordinate);
                emit updateLastPoint(coordinate);
            }
        }
    } else {
        // Add the very first trajectory point to the list
        _lastPoint = coordinate;
        _points.append(QVariant::fromValue(coordinate));
        emit pointAdded(coordinate);
    }
}

void TrajectoryPoints::_vehicleCoordinateGps1Changed(QGeoCoordinate coordinate)
{
    if (!_lastPointGps1.isValid()) {
        _lastPointGps1 = coordinate;
        _pointsGps1.append(QVariant::fromValue(coordinate));
        emit updateLastPoint(coordinate);
        return;
    }

    double distance = _lastPointGps1.distanceTo(coordinate);
    if (distance < _distanceTolerance) {
        return;
    }

    double newAzimuth = _lastPointGps1.azimuthTo(coordinate);
    if (qIsNaN(_lastAzimuthGps1) || qAbs(newAzimuth - _lastAzimuthGps1) > _azimuthTolerance) {
        _lastAzimuthGps1 = _lastPointGps1.azimuthTo(coordinate);
        _lastPointGps1 = coordinate;
        _pointsGps1.append(QVariant::fromValue(coordinate));
        emit pointAdded(coordinate);
    } else {
        _lastPointGps1 = coordinate;
        _pointsGps1[_pointsGps1.count() - 1] = QVariant::fromValue(coordinate);
        emit updateLastPoint(coordinate);
    }
}

void TrajectoryPoints::_vehicleCoordinateGps2Changed(QGeoCoordinate coordinate)
{
    if (!_lastPointGps2.isValid()) {
        _lastPointGps2 = coordinate;
        _pointsGps2.append(QVariant::fromValue(coordinate));
        emit updateLastPoint(coordinate);
        return;
    }

    double distance = _lastPointGps2.distanceTo(coordinate);
    if (distance < _distanceTolerance) {
        return;
    }

    double newAzimuth = _lastPointGps2.azimuthTo(coordinate);
    if (qIsNaN(_lastAzimuthGps2) || qAbs(newAzimuth - _lastAzimuthGps2) > _azimuthTolerance) {
        _lastAzimuthGps2 = _lastPointGps2.azimuthTo(coordinate);
        _lastPointGps2 = coordinate;
        _pointsGps2.append(QVariant::fromValue(coordinate));
        emit pointAdded(coordinate);
    } else {
        _lastPointGps2 = coordinate;
        _pointsGps2[_pointsGps2.count() - 1] = QVariant::fromValue(coordinate);
        emit updateLastPoint(coordinate);
    }
}

void TrajectoryPoints::start(void)
{
    clear();
    connect(_vehicle, &Vehicle::coordinateChanged, this, &TrajectoryPoints::_vehicleCoordinateChanged);
    connect(_vehicle, &Vehicle::coordinateGps1Changed, this, &TrajectoryPoints::_vehicleCoordinateGps1Changed);
    connect(_vehicle, &Vehicle::coordinateGps2Changed, this, &TrajectoryPoints::_vehicleCoordinateGps2Changed);
}

void TrajectoryPoints::stop(void)
{
    disconnect(_vehicle, &Vehicle::coordinateChanged, this, &TrajectoryPoints::_vehicleCoordinateChanged);
    disconnect(_vehicle, &Vehicle::coordinateGps1Changed, this, &TrajectoryPoints::_vehicleCoordinateGps1Changed);
    disconnect(_vehicle, &Vehicle::coordinateGps2Changed, this, &TrajectoryPoints::_vehicleCoordinateGps2Changed);
}

void TrajectoryPoints::clear(void)
{
    _points.clear();
    _pointsGps2.clear();
    _pointsGps1.clear();
    _lastPoint = _lastPointGps1 = _lastPointGps2 = QGeoCoordinate();
    _lastAzimuth = _lastAzimuthGps1 = _lastAzimuthGps2 = qQNaN();
    _lastPoint = QGeoCoordinate();
    _lastAzimuth = qQNaN();
    emit pointsCleared();
}
