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

	// Search function return lists of day keys like "10/1/2026" that
	// can then be converted into month, day, and year in the JS
	Q_INVOKABLE QStringList searchDays(QString needle, 
			bool poop, bool food, bool notes, bool weights);

	Q_INVOKABLE QString getDiaryFile();
	Q_INVOKABLE QString getDiaryDirectory();
	Q_INVOKABLE void setDiaryFile(const QString &fname);

	// dayOfWeek helper to not force C++ to find it, since it's easy to get in JS
	Q_INVOKABLE QString getDayString(const QString &dayOfWeek, int month, int day, int year);

	Q_INVOKABLE QString updateDay(const QString &dayString, bool remove);
};
