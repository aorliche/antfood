import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
	id: root

	title: i18nc("@title:window", "KFoodDiary")

	pageStack.initialPage: CalendarView {
		id: calendarView
	}
}
