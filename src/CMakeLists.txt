add_executable(kfooddiary)

ecm_add_qml_module(kfooddiary
    URI
    org.kde.kfooddiary
)

target_sources(kfooddiary
    PRIVATE
    main.cpp
	diary_read_write.cpp
)

ecm_target_qml_sources(kfooddiary
    SOURCES
    qml/Main.qml
	qml/CalendarView.qml
)

target_link_libraries(kfooddiary
    PRIVATE
    Qt6::Quick
    Qt6::Qml
    Qt6::Gui
    Qt6::QuickControls2
    Qt6::Widgets
    KF6::I18n
    KF6::CoreAddons
    KF6::IconThemes
)

install(TARGETS kfooddiary ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})

