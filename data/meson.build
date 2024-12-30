subdir('scss')

targets = files(
    'ui/utils/FlatButton.blp',
    'ui/utils/Popup.blp',

    'ui/ControlPanel.blp',
    'ui/DynamicIsland.blp',
    'ui/Runner.blp',
    'ui/RunnerButton.blp',
    'ui/StatusBar.blp',

    'ui/widgets/Mpris.blp',
    'ui/widgets/QuickPanel.blp',
    'ui/widgets/NetworkPanel.blp',
    'ui/widgets/BluetoothPanel.blp',
    'ui/widgets/CryptoWallet.blp',
    'ui/widgets/BatteryMode.blp',
    'ui/widgets/HeaderPanel.blp',
)

blueprints = custom_target(
    'blueprints',
    input: targets,
    output: '.',
    command: [
        find_program('blueprint-compiler'),
        'batch-compile',
        '@OUTPUT@',
        '@CURRENT_SOURCE_DIR@',
        '@INPUT@',
    ],
)

project_resources = gnome.compile_resources(
    project_name + '-resources',
    project_name + '.gresource.xml',
    dependencies: [blueprints, scss],
)