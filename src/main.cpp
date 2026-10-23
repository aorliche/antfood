#include <QApplication>
#include <QQmlApplicationEngine>
#include <QtQml>
#include <QUrl>
#include <QQuickStyle>
#include <KLocalizedContext>
#include <KLocalizedString>
#include <KIconTheme>

// Database file
/*#include <stdio.h>
#include <stdlib.h>
#include <dirent.h>
#include <errno.h>
#include <string.h>
#include <sys/stat.h>*/

#include "diary_read_write.h"

using namespace std;

/*void check_and_create_dir(const char *home, const char *suffix) {
	if (strlen(home) + strlen(suffix) > 1000) {
		fprintf(stderr, "Directory name too long: %s/%s\n", home, suffix);
		exit(1);
	}
	char buf[1024];
	snprintf(buf, 1023, "%s/%s", home, suffix);
	DIR *dir = opendir(buf);
	if (dir) {
		closedir(dir);
	} else if (ENOENT == errno) {
		mkdir(buf, 0755);
	} else {
		fprintf(stderr, "Other error opening directory: %s/%s\n", home, suffix);
		exit(1);
	}
}*/

int main(int argc, char *argv[])
{
    KIconTheme::initTheme();
    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("Diary");
    QApplication::setOrganizationName(QStringLiteral("KDE"));
    QApplication::setOrganizationDomain(QStringLiteral("kde.org"));
    QApplication::setApplicationName(QStringLiteral("KFoodDiary"));
    QApplication::setDesktopFileName(QStringLiteral("org.kde.kfooddiary"));

    QApplication::setStyle(QStringLiteral("breeze"));
    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QQmlApplicationEngine engine;

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));
    engine.loadFromModule("org.kde.kfooddiary", "Main");

    if (engine.rootObjects().isEmpty()) {
        return -1;
    }

	// Database file
	/*const char *home = getenv("HOME");
	if (!home) {
		fprintf(stderr, "Failed to getenv(\"HOME\")\n");
		return -1;
	}

	check_and_create_dir(home, ".local");
	check_and_create_dir(home, ".local/share");
	check_and_create_dir(home, ".local/share/kfooddiary");*/

	/*char dbpath[1024];
	int nw = snprintf(dbpath, sizeof(dbpath)-1, "%s/.local/share/kfooddiary/db.sqlite3", home);
	if (!nw) {
		fprintf(stderr, "Failed to write dbpath\n");
		return -1;
	}*/

	// Kirigami
    return app.exec();
}
