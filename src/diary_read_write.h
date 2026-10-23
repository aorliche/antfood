#pragma once

#include <QObject>
#include <qqmlintegration.h>

class Backend : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_SINGLETON

public:
	explicit Backend(QObject *parent = nullptr);

	Q_INVOKABLE int getCalories(int month, int day, int year);
	Q_INVOKABLE QStringList getWeights(int month, int day, int year);
};
