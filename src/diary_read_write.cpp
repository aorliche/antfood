#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <regex>
#include <cstdlib>
#include <unordered_map>

#include "diary_read_write.h"

#define DIARY_FNAME "/home/anton/Documents/Diary/diary.txt"

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

// Day matches a search term
/*func (day *Day) Search(
	needle string, 
	searchPoop bool, 
	searchFood bool, 
	searchNotes bool, 
	searchWeights bool) bool {

	needle = strings.ToLower(needle)
	if searchPoop {
		for _, poop := range day.PoopStrings {
			if strings.Contains(strings.ToLower(poop), needle) {
				return true
			}
		}
	}
	if searchFood {
		for _, food := range day.FoodItems {
			if strings.Contains(strings.ToLower(food.Name), needle) {
				return true
			}
		}
	}
	if searchNotes {
		for _, note := range day.NoteStrings {
			if strings.Contains(strings.ToLower(note), needle) {
				return true
			}
		}
	}
	if searchWeights {
		for _, weight := range day.WeightStrings {
			if strings.Contains(strings.ToLower(weight), needle) {
				return true
			}
		}
	}
	return false
}*/

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
	const regex date_regex("^([A-z]+) (\\d+)/(\\d+)/(\\d+)$");
	const regex food_regex1("^(\\d+) ([A-z/ ']+) \\((\\d+)\\)$");
	const regex food_regex2("^([A-z/ ']+) \\((\\d+)\\)$");
	const regex food_regex3("^([A-z/ 0-9']+)$");
	smatch pieces_match;

	if (!diary_file.is_open()) {
		cerr << "Failed to open diary file "s + string(DIARY_FNAME) << endl;
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

Backend::Backend(QObject *parent) 
	: QObject(parent) {
	vector<diary_day> days = read_diary_file(DIARY_FNAME);
	for (const diary_day &day : days) {
		string key = day.date_key();
		diary_map[key] = day;
	}
}

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

/*int main(void) {
	vector<diary_day> days = read_diary_file(DIARY_FNAME);
	cout << days.size() << endl;
	for (diary_day &day : days) {
		vector<string> ws = day.weights_as_strs();
		if (ws.size() > 0) {
			for (const string &w : ws) {
				cout << w << endl;
			}
		}
	}
}*/
