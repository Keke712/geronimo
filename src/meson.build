source_files = [
    'Main.vala',
    'App.vala',
    'StatusBar.vala',
    'QuickSettings.vala',
    'QuickPanel.vala',
    'QuickSettingsButton.vala',
    'Runner.vala',
    'RunnerButton.vala',
    'Mpris.vala',
    'NetworkPanel.vala',
    'BluetoothPanel.vala',
    'Utils/Popup.vala',
    'Utils/Calculator.vala',
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
        
        dependency('astal-wireplumber-0.1'),
        dependency('astal-mpris-0.1'),
        dependency('astal-hyprland-0.1'),
        dependency('astal-notifd-0.1'),
        dependency('astal-network-0.1'),
        dependency('astal-bluetooth-0.1'),
        dependency('astal-battery-0.1'),
        dependency('astal-apps-0.1'),

        dependency('astal-io-0.1'),
        dependency('astal-4-4.0'),
        dependency('gio-unix-2.0'),
        dependency('libadwaita-1'),
    ],
    link_args: ['-lm'], # Link math library
    install: true,
)