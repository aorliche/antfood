import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import org.kde.kirigami as Kirigami

Kirigami.Page {
	id: graphPage
	
	title: i18nc("@title", "Food Diary Graphs")
	
	Column {
		anchors.fill: parent
		spacing: 10
		anchors.margins: 10

		Canvas {
			id: graphCanvas
			width: parent.width
			height: 500 

			property int leftAxisWidth: 60
			property int rightAxisWidth: 60
			property int bottomAxisHeight: 50

			function getTicks(min, max, n, round) {
				const tickMin = Math.floor(min/round)*round;
				const tickMax = Math.floor(max/round)*round;
				let mult = round;
				while ((tickMax-tickMin)/mult > n) {
					mult += round;
				}
				const ticks = [];
				for (let tick = tickMin; tick < tickMax; tick += mult) {
					ticks.push(tick);
				}
				return ticks;
			}

			onPaint: {
				const ctx = getContext('2d');
				ctx.clearRect(0, 0, width, height);

				const graphWidth = width-leftAxisWidth-rightAxisWidth;
				const graphHeight = height-bottomAxisHeight;

				// Draw background
				ctx.fillStyle = '#112';
				ctx.fillRect(leftAxisWidth, 0, graphWidth, graphHeight);

				// Draw axes
				ctx.strokeStyle = '#ddd';
				ctx.strokeRect(leftAxisWidth, 0, graphWidth, graphHeight);

				ctx.font = "18px sans-serif";

				// Draw axis labels
				ctx.save();
				ctx.translate(leftAxisWidth-45, height/2);
				ctx.rotate(-Math.PI/2);
				ctx.textAlign = 'center';
				ctx.fillStyle = '#f33';
				ctx.fillText('Calories', 0, 0);
				ctx.restore();
				
				ctx.save();
				ctx.translate(width-15, height/2);
				ctx.rotate(Math.PI/2);
				ctx.textAlign = 'center';
				ctx.fillStyle = '#44f';
				ctx.fillText('Weight', 0, 0);
				ctx.restore();

				ctx.fillStyle = '#ddd';
				const tm = ctx.measureText('Date');
				ctx.fillText('Date', leftAxisWidth+graphWidth/2-tm.width/2, graphHeight+40);

				function daysBetween(d1, d2) {
					return Math.round(d2 - d1)/60/60/24/1000;
				}

				// Draw graphs
				// Note: do not remove the array-ifying operation
				// Even though it doesn't give at() method, it is
				// required for modifications we do later on
				const cals = [...Backend.getCalorieGraph()];
				const startDateCals = new Date(cals[0].split('-')[0]);
				const endDateCals = new Date(cals[cals.length-1].split('-')[0]);

				const ws = [...Backend.getWeightsGraph()];
				const startDateWs = new Date(ws[0].split('-')[0]);
				const endDateWs = new Date(ws[ws.length-1].split('-')[0]);

				let startDate = startDateCals > startDateWs ? startDateWs : startDateCals;
				let endDate = endDateCals > endDateWs ? endDateCals : endDateWs;
				let nDays = daysBetween(startDate, endDate) + 1;

				// Update based on slider
				startDate.setDate(startDate.getDate() + Math.round(dateSlider.first.value/100*nDays));
				endDate.setDate(endDate.getDate() + 
					Math.round(dateSlider.second.value/100*nDays) - nDays);
				nDays = daysBetween(startDate, endDate) + 1;

				let maxCals = 0, minCals = 10000, maxW = 0, minW = 1000;

				for (let i=0; i<cals.length; i++) {
					const parts = cals[i].split('-');
					const dat = new Date(parts[0]);
					const c = parseInt(parts[1]);
					cals[i] = [daysBetween(startDate, dat), c];
					if (c > maxCals) {
						maxCals = c;
					}
					if (c < minCals) {
						minCals = c;
					}
				}

				const calRange = maxCals - minCals + 200;

				for (let i=0; i<ws.length; i++) {
					const parts = ws[i].split('-');
					const dat = new Date(parts[0]);
					const w = parseInt(parts[1]);
					ws[i] = [daysBetween(startDate, dat), w];
					if (w > maxW) {
						maxW = w;
					}
					if (w < minW) {
						minW = w;
					}
				}

				const wsRange = maxW - minW + 10;

				// Draw ticks
				const calTicks = getTicks(minCals-100, maxCals+100, 10, 100);

				for (let i=0; i<calTicks.length; i++) {
					const y = graphHeight - (calTicks[i] - minCals + 100) / calRange * graphHeight;
					ctx.strokeStyle = '#ddd';
					ctx.lineWidth = 1;
					ctx.beginPath();
					ctx.moveTo(leftAxisWidth, y);
					ctx.lineTo(leftAxisWidth + graphWidth, y);
					ctx.stroke();
					ctx.fillStyle = '#ddd';
					ctx.font = '13px sans-serif';
					ctx.fillText(calTicks[i], leftAxisWidth-35, y);
				}

				const wsTicks = getTicks(minW-5, maxW+5, 10, 1);

				for (let i=0; i<wsTicks.length; i++) {
					const y = graphHeight - (wsTicks[i] - minW + 5) / wsRange * graphHeight;
					ctx.fillStyle = '#ddd';
					ctx.font = '13px sans-serif';
					ctx.fillText(wsTicks[i], leftAxisWidth+graphWidth+5, y);
				}

				// x axis
				const dateTicks = getTicks(0, nDays, 10, 1);

				for (let i=0; i<dateTicks.length; i++) {
					const x = leftAxisWidth + dateTicks[i] / nDays * graphWidth;
					ctx.strokeStyle = '#ddd';
					ctx.lineWidth = 1;
					ctx.beginPath();
					ctx.moveTo(x, 0);
					ctx.lineTo(x, graphHeight);
					ctx.stroke();
					const today = new Date(startDate);
					today.setDate(today.getDate() + dateTicks[i]);
					// Not sure about the +1 on getDate, some kind of bug
					const lab = `${today.getMonth()+1}/${today.getDate()+1}/${today.getFullYear()}`;
					ctx.fillStyle = '#ddd';
					ctx.font = '13px sans-serif';
					const tm = ctx.measureText(lab);
					ctx.fillText(lab, x-tm.width/2, graphHeight+15);
				}

				const calTrendData = [];
				const wsTrendData = [];
				const dx = graphWidth / nDays;

				// Draw circles
				for (let i=0; i<cals.length; i++) {
					const x = cals[i][0] / nDays * graphWidth + leftAxisWidth;
					const y = graphHeight - 
						((cals[i][1] - minCals + 100) / calRange * graphHeight);
					// Respect start and end range
					if (x < leftAxisWidth) {
						continue;
					}
					if (x > leftAxisWidth + graphWidth) {
						break;
					}
					calTrendData.push([x,y]);
					if (viewCaloriesCB.checked) {
						ctx.beginPath();
						ctx.arc(x, y, 5, 0, 2*Math.PI);
						ctx.fillStyle = '#d99';
						ctx.fill();
					}
				}

				for (let i=0; i<ws.length; i++) {
					const x = ws[i][0] / nDays * graphWidth + leftAxisWidth;
					const y = graphHeight - 
						((ws[i][1] - minW + 5) / wsRange * graphHeight);
					// Respect start and end range
					if (x < leftAxisWidth) {
						continue;
					}
					if (x > leftAxisWidth + graphWidth) {
						break;
					}
					wsTrendData.push([x,y]);
					if (viewWeightsCB.checked) {
						ctx.beginPath();
						ctx.arc(x, y, 5, 0, 2*Math.PI);
						ctx.fillStyle = '#66d';
						ctx.fill();
					}
				}

				// Draw trendlines

				function drawTrendline(data, radius, color) {
					let gotFirst = false;
					let runIdx = 0;

					ctx.beginPath();
					for (let i=0; i<nDays; i++) {
						const x = i*dx + leftAxisWidth;
						while (runIdx < data.length && data[runIdx][0] < x) {
							runIdx++;
						}
						if (runIdx > 0) {
							runIdx--;
						}
						// Don't start with a long flat line if we're missing data
						if (data[runIdx][0] - x > radius) {
							continue;
						}
						let ys = [];
						// Read back radius
						let idx = runIdx;
						while (idx >= 0 && x - data[idx][0] <= radius) {
							ys.push(data[idx][1]);
							idx--;
						}
						// Read forward radius
						idx = runIdx;
						while (idx < data.length && data[idx][0] - x <= radius) {
							ys.push(data[idx][1]);
							idx++;
						}
						let y = 0;
						if (ys.length > 0) {
							for (let j=0; j<ys.length; j++) {
								y += ys[j]/ys.length;
							}
							if (!gotFirst) {
								gotFirst = true;
								ctx.moveTo(x, y);
							} else {
								ctx.lineTo(x, y);
							}
						} 
					}
					ctx.lineWidth = 3;
					ctx.strokeStyle = color;
					ctx.stroke();
				}

				if (viewCaloriesTrendlineCB.checked) {
					drawTrendline(calTrendData, radiusSlider.value*dx, '#f33');
				}
				if (viewWeightsTrendlineCB.checked) {
					drawTrendline(wsTrendData, radiusSlider.value*dx, '#44f');
				}
			}
		}

		Row {
			spacing: 10

			Controls.Label {
				text: 'Display:'
				anchors.top: parent.top
				anchors.topMargin: 2
			}

			Controls.CheckBox {
				id: viewCaloriesCB
				text: 'Calories'
				checked: true
				onCheckedChanged: {
					graphCanvas.requestPaint();
				}
			}

			Controls.CheckBox {
				id: viewCaloriesTrendlineCB
				text: 'Calories Trendline'
				checked: true
				onCheckedChanged: {
					graphCanvas.requestPaint();
				}
			}

			Controls.CheckBox {
				id: viewWeightsCB
				text: 'Weights'
				checked: true
				onCheckedChanged: {
					graphCanvas.requestPaint();
				}
			}
			
			Controls.CheckBox {
				id: viewWeightsTrendlineCB
				text: 'Weights Trendline'
				checked: true
				onCheckedChanged: {
					graphCanvas.requestPaint();
				}
			}
		}

		Row {
			spacing: 10

			Controls.Label {
				text: 'Trendline smoothing:'
				anchors.top: parent.top
				anchors.topMargin: 2
			}

			Controls.Slider {
				id: radiusSlider
				width: Kirigami.Units.gridUnit * 25

				from: 1
				to: 25
				value: 5
				stepSize: 1

				onMoved: {
					graphCanvas.requestPaint();
					radiusLabel.text = value + " days"
				}
			}

			Controls.Label {
				id: radiusLabel
				text: radiusSlider.value + " days"
				anchors.top: parent.top
				anchors.topMargin: 2
			}
		}

		Row {
			spacing: 10

			Controls.Label {
				text: 'Start and end dates:'
				anchors.top: parent.top
				anchors.topMargin: 2
				anchors.rightMargin: 5
			}

			Controls.RangeSlider {
				id: dateSlider
				width: Kirigami.Units.gridUnit * 25

				from: 0
				to: 100
				first.value: 0
				second.value: 100

				first.onMoved: {
					graphCanvas.requestPaint();
				}
				second.onMoved: {
					graphCanvas.requestPaint();
				}
			}
		}
	}
}
