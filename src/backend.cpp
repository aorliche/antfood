#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <regex>
#include <cstdlib>
#include <unordered_map>
#include <algorithm>
#include <cctype>

#include <QDir>
#include <QFileInfo>
#include <QTemporaryFile>

#include "backend.h"

#define LOCAL_DIR "/.local/share/kfooddiary"

using namespace std;

struct food_item {
	string name;
	int quantity;
	int calories;

	friend ostream& operator<<(ostream &os, const food_item &item);
};

struct diary_day {
	string day_of_week;
	int month;
	int day;
	int year;
	vector<string> poop_strings;
	vector<food_item> food_items;
	vector<string> note_strings;
	vector<string> weight_strings;

	int calories() const;
	vector<string> weights_as_strs() const;
	string date_key() const;

	friend ostream& operator<<(ostream &os, const diary_day &day);
};

// Global variables
string diary_fname;

// Main data structure
// String key like "12/31/2026"
unordered_map<string, diary_day> diary_map;

ostream &operator<<(ostream &os, const food_item &item) {
	if (item.quantity > 0 && item.calories > 0) {
		os << item.quantity << " " << item.name << " (" << item.calories << ")";
	} else if (item.calories > 0) {
		os << item.name << " (" << item.calories << ")";
	} else {
		os << item.name;
	}
	return os;
}

int diary_day::calories() const {
	int total = 0;
	for (size_t i=0; i<this->food_items.size(); i++) {
		total += this->food_items[i].calories;
	}
	return total;
}
	
ostream& operator<<(ostream &os, const diary_day &day) {
	// Date header
	os << day.day_of_week << " " << day.month << "/" << day.day << "/" << (day.year - 2000) << endl;
	// Poop strings
	for (const string &poop_string : day.poop_strings) {
		os << poop_string << endl;
	}
	// Food items
	if (day.food_items.size() > 0) {
		int cur_size = 7;
		os << "- Ate: ";
		for (const food_item &item : day.food_items) {
			stringstream ss;
			ss << item;
			string s = ss.str();
			// First item
			if (cur_size == 7) {
				cur_size += s.size();
				os << s;
			// Wrap
			} else if (cur_size + s.size() > 108) {
				os << endl << "- Ate: ";
				cur_size = 7 + s.size();
				os << s;
			// Follows another item
			} else {
				cur_size += s.size() + 2;
				os << ", " << s;
			}
		}
		os << endl;
	}
	// Total calories
	int cals = day.calories();
	if (cals > 0) {
		os << "- Total calories: " << cals << "-" << (cals+200) << endl;
	}
	// Notes
	for (const string &note : day.note_strings) {
		os << note << endl;
	}
	// Weight strings
	for (const string &weight : day.weight_strings) {
		os << weight << endl;
	}
	return os;
}

vector<string> diary_day::weights_as_strs() const {
	vector<string> weights;
	const regex reg("^- Weight: ([0-9.]+) lbs\\..+");
	smatch parts;
	for (const string &w : this->weight_strings) {
		if (regex_match(w, parts, reg)) {
			weights.push_back(parts[1].str());
		}
	}
	return weights;
}

// Here year is 4-digit
string diary_day::date_key() const {
	stringstream ss;
	ss << this->month << "/" << this->day << "/" << this->year;
	return ss.str();
}

// Trim from the left (start)
void ltrim(string &s) {
    s.erase(0, s.find_first_not_of(" \t\n\r\f\v"));
}

// Trim from the right (end)
void rtrim(string &s) {
    s.erase(s.find_last_not_of(" \t\n\r\f\v") + 1);
}

// Trim from both ends
void trim(string &s) {
    rtrim(s);
    ltrim(s);
}

bool starts_with(const std::string& str, const std::string& prefix) {
    if (str.size() < prefix.size()) return false;
    return str.compare(0, prefix.size(), prefix) == 0;
}

vector<diary_day> read_diary_file(const string &fname) {
	string line;
	ifstream diary_file(fname);
	vector<diary_day> days;
	const regex date_regex("^([A-z]+) (\\d+)/(\\d+)/(\\d+)$");		// e.g. "Monday 10/26/26"
	const regex food_regex1("^(\\d+) ([A-z/ ']+) \\((\\d+)\\)$");	// Must have int quantity and calories
	const regex food_regex2("^([A-z/ 0-9']+) \\((\\d+)\\)$");		// Must have integer calories
	const regex food_regex3("^([A-z/ 0-9']+)$");					// No rules (some rules)
	smatch pieces_match;

	if (!diary_file.is_open()) {
		cerr << "Failed to open diary file "s + string(fname) << endl;
		return days;
	}

	while (getline(diary_file, line)) {
		trim(line);

		// Date or blank line
		if (line[0] != '-') {
			if (regex_match(line, pieces_match, date_regex)) {
				diary_day day;
				day.day_of_week = pieces_match[1].str();
				day.month = atoi(pieces_match[2].str().c_str());
				day.day = atoi(pieces_match[3].str().c_str());
				day.year = 2000 + atoi(pieces_match[4].str().c_str());
				days.push_back(day);
			}
		} else {
			// Inside a particular day
			line = line.substr(2);
			diary_day &day = days.back();
			// Poop string
			if (starts_with(line, "Pooped ")) {
				line = "- "s + line;
				day.poop_strings.push_back(line);
			// Total calories - we calculate from food items
			} else if (starts_with(line, "Total calories:")) {
				continue;
			// Weight string
			} else if (starts_with(line, "Weight: ")) {
				line = "- "s + line;
				day.weight_strings.push_back(line);
			// Food strings - broken up further
			} else if (starts_with(line, "Ate: ")) {
				line = line.substr(5);
				string token;
				stringstream ss(line);
				while (getline(ss, token, ',')) {
					food_item item = {""s, 0, 0};
					trim(token);
					if (regex_match(token, pieces_match, food_regex1)) {
						item.name = pieces_match[2].str();
						item.quantity = atoi(pieces_match[1].str().c_str());
						item.calories = atoi(pieces_match[3].str().c_str());
					} else if (regex_match(token, pieces_match, food_regex2)) {
						item.name = pieces_match[1].str();
						item.calories = atoi(pieces_match[2].str().c_str());
					} else if (regex_match(token, pieces_match, food_regex3)) {
						item.name = pieces_match[1].str();
					}
					// Check that we successfully parsed item
					if (item.name.size() > 0) {
						day.food_items.push_back(item);
					}
				}
			// Note string
			} else {
				line = "- "s + line;
				day.note_strings.push_back(line);
			}
		}
	}

	diary_file.close();

	return days;
}

void reload() {
	vector<diary_day> days = read_diary_file(diary_fname);
	for (const diary_day &day : days) {
		string key = day.date_key();
		diary_map[key] = day;
	}
}

// Constructor
Backend::Backend(QObject *parent) 
		: QObject(parent) {
	// Check and create local directory
	string local = QDir::homePath().toStdString() + string(LOCAL_DIR);
	QDir().mkpath(QString::fromStdString(local));
	// Read config file
	string conf_name = local + "/kfooddiary.conf"s;
	ifstream conf_file(conf_name);
	// The config file doesn't exist so write one first
	if (!conf_file.good()) {
		ofstream conf_file_out(conf_name);
		conf_file_out << "diary_file = " << local << "/diary.txt";
		conf_file_out.close();
		conf_file = ifstream(conf_name);
	}
	// Now do the read
	string line;
	const regex reg("^diary_file = ([A-z0-9/\\.]+)$");
	smatch parts;
	while (getline(conf_file, line)) {
		trim(line);
		if (regex_match(line, parts, reg)) {
			diary_fname = parts[1].str();
			break;
		}
	}
	// Whether or not we've successfully read the file
	// and whether it exists or not, initialize the data structures
	reload();
}

// QML Interface
int Backend::getCalories(int month, int day, int year) {
	stringstream ss;
	ss << month << "/" << day << "/" << year;
	string key = ss.str();
	auto it = diary_map.find(key);
	if (it != diary_map.end()) {
		auto day = it->second;
		return day.calories();
	} else {
		return 0;
	}
}

// QML Interface
QStringList Backend::getWeights(int month, int day, int year) {
	QStringList list;
	stringstream ss;
	ss << month << "/" << day << "/" << year;
	string key = ss.str();
	auto it = diary_map.find(key);
	if (it != diary_map.end()) {
		auto day = it->second;
		for (const string &w : day.weights_as_strs()) {
			list << QString::fromStdString(w);
		}
	} 
	return list;
}

// In-place
void to_lower(string &s) {
	transform(s.begin(), s.end(), s.begin(), [](unsigned char c) {
		return tolower(c);
	});
}

// QML Interface
QStringList Backend::searchDays(QString needle, 
		bool poop, bool food, bool notes, bool weights) {
	QStringList list;

	string needle2 = needle.toStdString(); // copy
	to_lower(needle2);

	for (const auto& pair : diary_map) {
		bool found = false;
		if (food) {
			for (const auto &item : pair.second.food_items) {
				stringstream ss;
				ss << item;
				string s = ss.str();
				to_lower(s);
				if (s.find(needle2) != string::npos) {
					found = true;
					break;
				}
			}
		}
		if (poop && !found) {
			for (const auto &str : pair.second.poop_strings) {
				string s = str;
				to_lower(s);
				if (s.find(needle2) != string::npos) {
					found = true;
					break;
				}
			}
		}
		if (notes && !found) {
			for (const auto &str : pair.second.note_strings) {
				string s = str;
				to_lower(s);
				if (s.find(needle2) != string::npos) {
					found = true;
					break;
				}
			}
		}
		if (weights && !found) {
			for (const auto &str : pair.second.weight_strings) {
				string s = str;
				to_lower(s);
				if (s.find(needle2) != string::npos) {
					found = true;
					break;
				}
			}
		}
		if (found) {
			list << QString::fromStdString(pair.first);
		}
	}
	return list;
}

// QML Interface
QString Backend::getDiaryFile() {
	return QString::fromStdString(diary_fname);
}

// QML Interface
QString Backend::getDiaryDirectory() {
	QFileInfo fileInfo(QString::fromStdString(diary_fname));
	QDir dir = fileInfo.absoluteDir();
	return dir.absolutePath();
}

// QML Interface
void Backend::setDiaryFile(const QString &fname) {
	// Update name and reload
	diary_fname = fname.toStdString();
	reload();
	// Update config file
	string local = QDir::homePath().toStdString() + string(LOCAL_DIR);
	string conf_name = local + "/kfooddiary.conf"s;
	ofstream conf_file_out(conf_name);
	conf_file_out << "diary_file = " << diary_fname;
	conf_file_out.close();
}

// QML Interface
QString Backend::getDayString(const QString &dayOfWeek, int month, int day, int year) {
	// If we find a day in our map, return its string representation
	stringstream ss;
	ss << month << "/" << day << "/" << year;
	string key = ss.str();
	auto it = diary_map.find(key);
	if (it != diary_map.end()) {
		stringstream ds;
		ds << it->second;
		return QString::fromStdString(ds.str());
	}
	// If we don't find a day, create a template for user to start filling in
	// Our key is slightly different
	stringstream ss2;
	ss2 << dayOfWeek.toStdString() << " " << month << "/" << day << "/" << (year - 2000) << endl;
	ss2 << "- Pooped small amount" << endl;
	ss2 << "- Ate: twinkie (200), 1/2 coke (100)" << endl;
	ss2 << "- Total calories: 300-500" << endl;
	ss2 << "- Didn't do much" << endl;
	ss2 << "- Weight: 180 lbs. (morning)" << endl;
	return QString::fromStdString(ss2.str());
}

// QML Interface
QString Backend::updateDay(const QString &dayString, bool remove) {
	// We do this in the worst way possible:
	// write dayString to a temp file and 
	// re-use read_diary_file to get a vector of days
	// Then update the map with the new day data (overwrite)
	// It's an error if more than one day results
	QTemporaryFile tempFile;

	if (!tempFile.open()) {
		return QStringLiteral("Failed to open temporary file");
	}

	QTextStream out(&tempFile);
	out << dayString;
	tempFile.close();

	vector<diary_day> days = read_diary_file(tempFile.fileName().toStdString());
	if (days.size() != 1) {
		stringstream ss;
		ss << "Bad number of days created: " << days.size();
		return QString::fromStdString(ss.str());
	}

	string key = days[0].date_key();

	// Remove the day
	if (remove) {
		size_t count = diary_map.erase(key);
		if (count != 1) {
			stringstream ss;
			ss << "Bad number of days erased: " << count;
			return QString::fromStdString(ss.str());
		}
	// Update the map
	} else {
		diary_map[key] = days[0];
	}

	// Empty string is no error
	return QString();
}
