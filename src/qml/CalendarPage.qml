import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.Page {
	id: calendarPage
	width: 1200
	height: 800

	title: i18nc("@title", "Food Diary")

	property list<string> searchHits: []

	function doSearch() {
		searchHits = Backend.searchDays(searchField.text, 
			searchPoopCB.checked,
			searchFoodCB.checked,
			searchNotesCB.checked,
			searchWeightsCB.checked);
		calendarCanvas.requestPaint();
	}

	Kirigami.Dialog {
		id: searchDialog
		title: i18nc("@title:window", "Search Diary")
		standardButtons: Kirigami.Dialog.Ok
		padding: Kirigami.Units.largeSpacing
		preferredWidth: Kirigami.Units.gridUnit * 25

		Kirigami.FormLayout {
			Controls.TextField {
				id: searchField
				Layout.preferredWidth: Kirigami.Units.gridUnit * 15
				Kirigami.FormData.label: i18nc("@label:textbox", "Search Text")
				onTextChanged: () => {
					doSearch();
				}
			}
			RowLayout {
				Controls.CheckBox {
					id: searchPoopCB
					text: "Poop"
					checked: false
					onCheckedChanged: () => {
						doSearch();
					}
				}
				Controls.CheckBox {
					id: searchFoodCB
					text: "Food"
					checked: true
					onCheckedChanged: () => {
						doSearch();
					}
				}
				Controls.CheckBox {
					id: searchNotesCB
					text: "Notes"
					checked: false
					onCheckedChanged: () => {
						doSearch();
					}
				}
				Controls.CheckBox {
					id: searchWeightsCB
					text: "Weights"
					checked: false
					onCheckedChanged: () => {
						doSearch();
					}
				}
			}
		}
	}

	Kirigami.Dialog {
		id: dayDialog
		title: i18nc("@title:window", "View/Edit Day")
		standardButtons: Kirigami.Dialog.Save | Kirigami.Dialog.Reset | Kirigami.Dialog.Cancel
		padding: Kirigami.Units.largeSpacing
		preferredWidth: Kirigami.Units.gridUnit * 25

		Controls.ScrollView {
			anchors.fill: parent
			contentWidth: availableWidth

			Controls.TextArea {
				id: dayTextArea
				wrapMode: Text.WordWrap
				selectByMouse: true
				persistentSelection: true

				leftPadding: Kirigami.Units.largeSpacing
				rightPadding: Kirigami.Units.largeSpacing
			}
		}

		// Create a handler for the reset button
		// (the reset button deletes the day - sets it back to the default template)
		Component.onCompleted: {
			const resetButton = standardButton(Kirigami.Dialog.Reset);

			if (resetButton) {
				resetButton.clicked.connect(() => {
					const error = Backend.updateDay(dayTextArea.text, true);
					if (error) {
						console.log(error);
						return;
					}
					dayDialog.close();
					calendarCanvas.requestPaint();
				});
			}
		}

		onAccepted: {
			const error = Backend.updateDay(dayTextArea.text, false);
			if (error) {
				console.log(error);
				return;
			}
			calendarCanvas.requestPaint();
		}
	}

	actions: [
		Kirigami.Action {
			text: "Current Month"
			icon.name: "go-home"
			onTriggered: () => {
				currentMonth = currentDate.getMonth()
				calendarCanvas.requestPaint();
			}
		},
		Kirigami.Action {
			text: "Search"
			icon.name: "search"
			onTriggered: () => {
				searchDialog.open();
			}
		},
		Kirigami.Action {
			text: "Graphs"
			icon.name: "office-chart-line"
			onTriggered: () => {
				root.pageStack.layers.push(graphPage);
			}
		},
	]

	property date currentDate: new Date()
	property int currentYear: currentDate.getFullYear()
	property int currentMonth: currentDate.getMonth()

	Column {
		anchors.fill: parent
		spacing: 10
		anchors.margins: 10

		// Navigation header
		RowLayout {
			width: parent.width
			height: 40
			spacing: 10

			Item {
				Layout.fillWidth: true
			}

			Controls.Button {
				text: 'Previous'
				icon.name: 'go-previous'

				onClicked: {
					if (currentMonth == 0) {
						currentMonth = 11;
						currentYear--;
					} else {
						currentMonth--;
					}
					calendarCanvas.requestPaint();
				}
			}

			Text {
				height: parent.height
				verticalAlignment: Text.AlignVCenter
				horizontalAlignment: Text.AlignHCenter
				font.pixelSize: 18
				font.bold: true
				color: '#ddd'
				text: Qt.locale().monthName(currentMonth, Locale.LongFormat) 
					+ " " + currentYear.toString()
			}
			
			Controls.Button {
				text: 'Next'
				icon.name: 'go-next'

				onClicked: {
					if (currentMonth == 11) {
						currentMonth = 0;
						currentYear++;
					} else {
						currentMonth++;
					}
					calendarCanvas.requestPaint();
				}
			}
			
			Item {
				Layout.fillWidth: true
			}
		}

		// Actual calendar
		Canvas {
			id: calendarCanvas
			width: parent.width
			height: parent.height-50

			// Drawing properties
			property int headerHeight: 30
			property int columns: 7
			property int rows: 6
			property double cellWidth: width / columns
			property double cellHeight: (height - headerHeight) / rows

			// Mouse tracking
			property int mouseX: 0
			property int mouseY: 0
			property bool hovering: false

			MouseArea {
				id: mouseArea
				anchors.fill: parent

				hoverEnabled: true

				onEntered: {
					calendarCanvas.hovering = true;
				}

				onPositionChanged: (mouse) => {
					calendarCanvas.mouseX = mouse.x;
					calendarCanvas.mouseY = mouse.y;
					calendarCanvas.requestPaint();
					if (mouse.y > calendarCanvas.headerHeight) {
						mouseArea.cursorShape = Qt.PointingHandCursor;
					} else {
						mouseArea.cursorShape = Qt.ArrowCursor;
					}
				}

				onExited: {
					calendarCanvas.hovering = false;
					calendarCanvas.requestPaint();
					mouseArea.cursorShape = Qt.ArrowCursor;
				}

				onClicked: (mouse) => {
					// Month metrics (duplicated)
					const firstDayOfMonth = new Date(currentYear, currentMonth, 1).getDay();
					const daysInMonth = new Date(currentYear, currentMonth+1, 0).getDate();
					const daysInPrevMonth = new Date(currentYear, currentMonth, 0).getDate();
					const today = new Date();

					// Days of week (duplicated)
					const daysOfWeek = 
						['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];

					// Get day corresponding to mouse position
					const r = Math.floor(
						(mouse.y - calendarCanvas.headerHeight)
						/calendarCanvas.cellHeight);
					const d = Math.floor(
						mouse.x/calendarCanvas.cellWidth);

					if (r < 0 || r > 6 || d < 0 || d > 7) {
						return;
					}
						
					const dayCount = r*7 + d - firstDayOfMonth + 1;
					let month, day, year;

					// Duplicated partly from onPaint method
					// We're in the previous month
					if (dayCount < 1) {
						day = daysInPrevMonth + dayCount;
						month = currentMonth - 1;
					// We're in the current month
					} else if (dayCount <= daysInMonth) {
						day = dayCount;
						month = currentMonth;
					// We're in the next month
					} else {
						day = dayCount - daysInMonth;
						month = currentMonth + 1;
					}

					// Zero-based months to one-based months
					// Plus some other fix-ups
					month = month+1;
					year = currentYear;
					if (month == 0) {
						month = 12;
						year = currentYear-1;
					} else if (month == 12) {
						month = 1;
						year = currentYear+1;
					}

					const dayStr = Backend.getDayString(daysOfWeek[d], month, day, year);
					dayTextArea.text = dayStr;
					dayDialog.open();
				}
			}

			onPaint: {
				const ctx = getContext('2d');
				ctx.clearRect(0, 0, width, height);

				// Day names header row
				ctx.font = 'bold 13px sans-serif';
				ctx.fillStyle = '#ddd';
				const daysOfWeek = 
					['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
				for (let d = 0; d < 7; d++) {
					const tm = ctx.measureText(daysOfWeek[d]);
					ctx.fillText(daysOfWeek[d], (d+0.5)*cellWidth - tm.width/2, headerHeight-10);
				}
				
				// Month metrics
				const firstDayOfMonth = new Date(currentYear, currentMonth, 1).getDay();
				const daysInMonth = new Date(currentYear, currentMonth+1, 0).getDate();
				const daysInPrevMonth = new Date(currentYear, currentMonth, 0).getDate();
				const today = new Date();

				ctx.fillStyle = '#555';

				function hoveringWithinDay(r, d) {
					if (!hovering) {
						return;
					}
					return mouseX >= d*cellWidth 
						&& mouseX <= (d+1)*cellWidth 
						&& mouseY >= headerHeight + r*cellHeight 
						&& mouseY <= headerHeight + (r+1)*cellHeight;
				}

				function drawCaloriesAndWeights(color1, color2, month, day, year, r, d) {
					if (month == 0) {
						month = 12;
						year--;
					} else if (month == 13) {
						month = 1;
						year++;
					}
					ctx.save();
					ctx.font = '13px sans-serif';
					const cal = Backend.getCalories(month, day, year);
					if (cal > 0) {
						ctx.fillStyle = color1;
						ctx.fillText('Calories: ' + cal, 
							d*cellWidth+25, headerHeight+r*cellHeight+20);
					}
					const ws = Backend.getWeights(month, day, year);
					for (let i=0; i<ws.length; i++) {
						ctx.fillStyle = color2;
						ctx.fillText(ws[i] + ' lbs.', 
							d*cellWidth+25, headerHeight+r*cellHeight+40+20*i);
					}
					ctx.restore();
				}

				// Fill in calendar cells
				for (let r = 0; r < 6; r++) {
					for (let d = 0; d < 7; d++) {
						const dayCount = r*7 + d - firstDayOfMonth + 1;
						let month, day, fillStyle, lineWidth;
						// We're in the previous month
						if (dayCount < 1) {
							day = daysInPrevMonth + dayCount;
							month = currentMonth - 1;
							fillStyle = '#222';
							lineWidth = 1;
						// We're in the current month
						} else if (dayCount <= daysInMonth) {
							day = dayCount;
							month = currentMonth;
							fillStyle = '#222239';
							lineWidth = 1;
							// We're in the current day
							if (day == today.getDate() 
									&& currentMonth == today.getMonth() 
									&& currentYear == today.getFullYear()) {
								fillStyle = '#335';
							}
						// We're in the next month
						} else {
							day = dayCount - daysInMonth;
							month = currentMonth + 1;
							fillStyle = '#222';
							lineWidth = 1;
						}
						// Highlight hovering
						if (hoveringWithinDay(r, d)) {
							fillStyle = '#335';
						}
						// Highlight search
						const key = `${month+1}/${day}/${currentYear}`;
						if (searchHits.includes(key)) {
							fillStyle = '#533';
						}
						ctx.fillStyle = fillStyle;
						ctx.fillRect(d*cellWidth, headerHeight+r*cellHeight, 
							cellWidth, cellHeight);
						ctx.fillStyle = '#bbb';
						ctx.fillText(day, d*cellWidth+5, headerHeight+r*cellHeight+20);
						ctx.strokeStyle = '#ddd';
						ctx.lineWidth = lineWidth;
						ctx.strokeRect(d*cellWidth, headerHeight+r*cellHeight, 
							cellWidth, cellHeight);
						// Get calories for today
						drawCaloriesAndWeights('#fff', '#fff',
							month+1, day, currentYear, r, d);
					}
				}

				// Draw border
				ctx.strokeStyle = '#aaa';
				ctx.lineWidth = 2;
				ctx.strokeRect(0, 0, width, height);
			}
		}
	}
}
