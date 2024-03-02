/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include "QmlObjectListModel.h"

#include <QGeoCoordinate>

class Vehicle;

class TrajectoryPoints : public QObject
{
    Q_OBJECT

public:
    TrajectoryPoints(Vehicle* vehicle, QObject* parent = nullptr);

    Q_INVOKABLE QVariantList list(void) const { return _points; }
    Q_INVOKABLE QVariantList listGps1(void) const { return _pointsGps1; }
    Q_INVOKABLE QVariantList listGps2(void) const { return _pointsGps2; }

    void start  (void);
    void stop   (void);

public slots:
    void clear  (void);

signals:
    void pointAdded     (QGeoCoordinate coordinate);
    void updateLastPoint(QGeoCoordinate coordinate);
    void pointsCleared  (void);

private slots:
    void _vehicleCoordinateChanged(QGeoCoordinate coordinate);
    void _vehicleCoordinateGps1Changed(QGeoCoordinate coordinate);
    void _vehicleCoordinateGps2Changed(QGeoCoordinate coordinate);

private:
    Vehicle*        _vehicle;
    QVariantList    _points;
    QVariantList    _pointsGps1;
    QVariantList    _pointsGps2;
    QGeoCoordinate  _lastPoint;
    QGeoCoordinate  _lastPointGps1;
    QGeoCoordinate  _lastPointGps2;
    double          _lastAzimuth;
    double          _lastAzimuthGps1;
    double          _lastAzimuthGps2;

    static constexpr double _distanceTolerance = 2.0;
    static constexpr double _azimuthTolerance = 1.5;
};
