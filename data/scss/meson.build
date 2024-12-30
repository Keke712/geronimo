sass = find_program('sass')

scss_deps = files(
    '_Colors.scss',
    '_Mpris.scss',
    '_ControlPanel.scss',
    '_StatusBar.scss',
    '_adw.scss',
    '_Runner.scss',
    '_Popup.scss',
    '_BatteryMode.scss',
    '_DynamicIsland.scss',
    '_Button.scss',
    'main.scss',
)

scss = custom_target(
    'scss',
    input: 'main.scss',
    output: 'geronimo.css',
    command: [
        sass,
        '@INPUT@',
        '@OUTPUT@',
    ],
    depend_files: scss_deps,
)