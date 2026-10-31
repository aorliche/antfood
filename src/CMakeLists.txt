add_executable(antfood)

ecm_add_qml_module(antfood
    URI
    io.github.aorliche.antfood
)

target_sources(antfood
    PRIVATE
    main.cpp
	backend.cpp
)

ecm_target_qml_sources(antfood
    SOURCES
    qml/Main.qml
	qml/CalendarPage.qml
	qml/GraphPage.qml
)

target_link_libraries(antfood
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

install(TARGETS antfood ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})

