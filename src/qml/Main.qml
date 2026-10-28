import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs as Dialogs
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
	id: root

	title: i18nc("@title:window", "KFoodDiary")

	Dialogs.FileDialog {
		id: fileDialog
		title: "Choose a diary file"
		fileMode: Dialogs.FileDialog.SaveFile
		options: Dialogs.FileDialog.DontConfirmOverwrite

		currentFolder: "file://" + Backend.getDiaryDirectory()
		currentFile: "file://" + Backend.getDiaryFile()
		nameFilters: ["Text files (*.txt)", "All files (*)"]

		onAccepted: {
			diaryFilenameField.text = selectedFile.toString().replace('file://', '')
		}
	}

	Kirigami.Dialog {
		id: settingsDialog
		title: i18nc("@title:window", "Settings")
		standardButtons: Kirigami.Dialog.Ok | Kirigami.Dialog.Cancel
		padding: Kirigami.Units.largeSpacing
		preferredWidth: Kirigami.Units.gridUnit * 25

		Kirigami.FormLayout {
			Controls.TextField {
				id: diaryFilenameField
				Layout.preferredWidth: Kirigami.Units.gridUnit * 20
				Kirigami.FormData.label: i18nc("@label:textbox", "Diary File")
			}

			Controls.Button {
				text: "Browse..."
				onClicked: {
					fileDialog.open();
				}
			}
		}

		onAccepted: {
			Backend.setDiaryFile(diaryFilenameField.text);
		}
	}

	globalDrawer: Kirigami.GlobalDrawer {
		isMenu: true
		actions: [
			Kirigami.Action {
				text: i18n("Settings")
				icon.name: "settings-configure"
				onTriggered: {
					diaryFilenameField.text = Backend.getDiaryFile();
					settingsDialog.open();
				}
			},
			Kirigami.Action {
				text: i18n("Quit")
				icon.name: "application-exit"
				shortcut: StandardKey.Quit
				onTriggered: Qt.quit()
			}
		]
	}

	pageStack.initialPage: CalendarPage {
		id: calendarPage
	}

	Component {
		id: graphPage
		GraphPage {}
	}
}
