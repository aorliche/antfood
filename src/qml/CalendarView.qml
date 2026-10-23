import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Item {
	id: calendarView
	width: 1200
	height: 800

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
				color: '#aaa'
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

			property int headerHeight: 30

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
			}

			onPaint: {
				const ctx = getContext('2d');
				ctx.clearRect(0, 0, width, height);

				const columns = 7;
				const rows = 6;
				const cellWidth = width / columns;
				const cellHeight = (height - headerHeight) / rows;

				// Day names header row
				ctx.font = 'bold 13px sans-serif';
				ctx.fillStyle = '#aaa';
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

				// Fill in calendar text
				let dayCount = -1;
				let nextMonth = false;
				for (let r = 0; r < 6; r++) {
					for (let d = 0; d < 7; d++) {
						// We're in previous month
						if (dayCount == -1 && d < firstDayOfMonth) {
							// Highlight hovering
							if (hoveringWithinDay(r, d)) {
								ctx.save();
								ctx.fillStyle = '#444';
								ctx.fillRect(d*cellWidth, headerHeight+r*cellHeight, 
									cellWidth, cellHeight);
								ctx.restore();
							}
							const day = daysInPrevMonth - (firstDayOfMonth - d) + 1;
							ctx.fillText(day, d*cellWidth+5, headerHeight+r*cellHeight+20);
							// Get calories for today
							drawCaloriesAndWeights('#aaa', '#99f',
								currentMonth, day, currentYear,
								r, d);
						}
						// We begin current month
						if (dayCount == -1 && d == firstDayOfMonth) {
							ctx.fillStyle = '#aaa';
							dayCount = 0;
						}
						if (dayCount > -1 && dayCount < daysInMonth) {
							dayCount++;
							// Highlight current day or hovering
							if (hoveringWithinDay(r, d) ||
									(dayCount == today.getDate() 
									&& currentMonth == today.getMonth() 
									&& currentYear == today.getFullYear())) {
								ctx.save();
								ctx.fillStyle = '#444';
								ctx.fillRect(d*cellWidth, headerHeight+r*cellHeight, 
									cellWidth, cellHeight);
								ctx.restore();
							} else if (dayCount > -1 && !nextMonth) {
								ctx.save();
								ctx.fillStyle = '#292929';
								ctx.fillRect(d*cellWidth, headerHeight+r*cellHeight, 
									cellWidth, cellHeight);
								ctx.restore();
							}
							ctx.fillText(dayCount, d*cellWidth+5, headerHeight+r*cellHeight+20);
							// Get calories for today
							const month = nextMonth ? currentMonth+2 : currentMonth+1;
							drawCaloriesAndWeights(nextMonth ? '#aaa' : '#fff', 
								nextMonth ? '#99f' : '#aaf',
								month, dayCount, currentYear,
								r, d);
						}
						// We begin next month
						if (dayCount == daysInMonth) {
							ctx.fillStyle = '#555';
							dayCount = 0;
							nextMonth = true;
						}
					}
				}

				// Draw border
				ctx.strokeStyle = '#aaa';
				ctx.lineWidth = 2;
				ctx.strokeRect(0, 0, width, height);

				ctx.lineWidth = 1;

				// Draw grid
				for (let d = 0; d < 7; d++) {
					ctx.beginPath();
					ctx.moveTo(d*cellWidth, 0);
					ctx.lineTo(d*cellWidth, height);
					ctx.stroke();
				}

				ctx.beginPath();
				ctx.moveTo(0, headerHeight);
				ctx.lineTo(width, headerHeight);
				ctx.stroke();

				for (let r = 0; r < rows; r++) {
					ctx.beginPath()
					ctx.moveTo(0, headerHeight + r*cellHeight);
					ctx.lineTo(width, headerHeight + r*cellHeight);
					ctx.stroke();
				}
			}
		}
	}
}
