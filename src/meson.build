source_files = [
    'core/Main.vala',
    'core/App.vala',
    
    'StatusBar.vala',
    'QuickSettings.vala',
    'CenterPanel.vala',
    'Runner.vala',
    'RunnerButton.vala',

    'widgets/QuickPanel.vala',
    'widgets/Mpris.vala',
    'widgets/NetworkPanel.vala',
    'widgets/BluetoothPanel.vala',
    'widgets/CryptoWallet.vala',
    'widgets/BatteryMode.vala',
    'widgets/HeaderPanel.vala',

    'utils/FlatButton.vala',
    'utils/Popup.vala',
    'utils/Crypto.vala',
    'utils/Calculator.vala',
    'utils/UPower.vala',
]

executable(
    project_name,
    project_resources,
    sources: source_files,
    vala_args: ['--gresourcesdir=data/'],
    
    dependencies: [
        dependency('gtk4'),
        dependency('gtk4-layer-shell-0'),
        dependency('libnm'),
        # Crypto
        dependency('json-glib-1.0'),
        dependency('libsoup-2.4'),
        # Astal librairies
        dependency('astal-wireplumber-0.1'),
        dependency('astal-mpris-0.1'),
        dependency('astal-hyprland-0.1'),
        dependency('astal-notifd-0.1'),
        dependency('astal-network-0.1'),
        dependency('astal-bluetooth-0.1'),
        dependency('astal-battery-0.1'),
        dependency('astal-apps-0.1'),
        # Astal core libraries
        dependency('astal-io-0.1'),
        dependency('astal-4-4.0'),
        #
        dependency('gio-unix-2.0'),
        dependency('libadwaita-1'),
    ],
    link_args: ['-lm'], # Link math library
    install: true,
)