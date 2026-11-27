# Data files: desktop entries, AppStream metadata, icons, helper scripts and
# Lua scripts documentation

fs = import('fs')

if host_system not in ['windows', 'darwin', 'android', 'emscripten']
    #
    # Desktop entries
    #
    desktop_mimetypes = ''
    foreach line : fs.read('vlc.desktop.mimetypes').split('\n')
        mimetype = line.split('#')[0].strip()
        if mimetype != ''
            desktop_mimetypes += mimetype + ';'
        endif
    endforeach

    desktop_conf = configuration_data()
    desktop_conf.set('bindir', bindir_path)
    desktop_conf.set('MIMETYPES', desktop_mimetypes)

    desktop_file_validate = find_program('desktop-file-validate', required: false)

    foreach name : ['vlc', 'vlc-openbd', 'vlc-opendvd', 'vlc-openvcd', 'vlc-opencda']
        desktop_file = configure_file(
            input: f'@name@.desktop.in',
            output: f'@name@.desktop',
            configuration: desktop_conf,
            install: true,
            install_dir: sysdatadir_path / 'applications',
        )
        if desktop_file_validate.found()
            test(f'validate @name@.desktop', desktop_file_validate,
                args: [desktop_file],
                suite: 'share')
        endif
    endforeach

    #
    # KDE Solid actions
    #
    kde_solid_dir = get_option('kde_solid_dir')
    if kde_solid_dir != ''
        install_data(
            'solid/vlc-openbd.desktop',
            'solid/vlc-opencda.desktop',
            'solid/vlc-opendvd.desktop',
            'solid/vlc-openvcd.desktop',
            install_dir: sysdatadir_path / kde_solid_dir,
        )
    endif

    #
    # AppStream metadata
    #
    version_date = run_command(
        find_program('../buildsystem/version-date.py'), vlc_src_root,
        check: true,
    ).stdout().strip()

    appdata_conf = configuration_data()
    appdata_conf.set('VERSION', vlc_version)
    appdata_conf.set('VERSION_DATE', version_date)
    appdata_conf.set('LIBVLC_ABI_MAJOR', libvlc_abi_version_major)

    appdata_install_dir = sysdatadir_path / 'metainfo'
    if get_option('nls').allowed() and find_program('msgfmt', required: false).found()
        appdata_in = configure_file(
            input: 'org.videolan.vlc.appdata.xml.in.in',
            output: 'org.videolan.vlc.appdata.xml.in',
            configuration: appdata_conf,
        )
        import('i18n').merge_file(
            input: appdata_in,
            output: 'org.videolan.vlc.appdata.xml',
            type: 'xml',
            po_dir: '../po',
            install: true,
            install_dir: appdata_install_dir,
        )
    else
        configure_file(
            input: 'org.videolan.vlc.appdata.xml.in.in',
            output: 'org.videolan.vlc.appdata.xml',
            configuration: appdata_conf,
            install: true,
            install_dir: appdata_install_dir,
        )
    endif
endif

if host_system != 'windows'
    #
    # Icons
    #
    install_data('icons/vlc.ico', install_dir: pkgdatadir_path)

    hicolor_icons = {
        '16x16': ['vlc.png', 'vlc.xpm'],
        '32x32': ['vlc.png', 'vlc.xpm', 'vlc-xmas.xpm', 'vlc-aprilfools.xpm'],
        '48x48': ['vlc.png', 'vlc-xmas.png', 'vlc-aprilfools.png'],
        '128x128': ['vlc.png', 'vlc-xmas.png', 'vlc-kb.png', 'vlc-aprilfools.png'],
        '256x256': ['vlc.png'],
    }
    foreach size, icons : hicolor_icons
        foreach icon : icons
            install_data('icons' / size / icon,
                install_dir: sysdatadir_path / 'icons/hicolor' / size / 'apps')
        endforeach
    endforeach

    #
    # Scripts
    #
    install_data(
        'utils/audio-vlc-default.sh',
        'utils/video-vlc-default.sh',
        install_dir: pkgdatadir_path / 'utils',
        install_mode: 'rwxr-xr-x',
    )
endif

#
# Lua scripts documentation
#
if host_system != 'windows' and lua_dep.found() and get_option('lua').allowed()
    install_data(
        'lua/README.txt',
        'lua/extensions/README.txt',
        'lua/http/requests/README.txt',
        'lua/intf/README.txt',
        'lua/intf/dumpmeta.lua',
        'lua/meta/README.txt',
        'lua/meta/art/README.txt',
        'lua/meta/art/01_googleimage.lua',
        'lua/meta/fetcher/README.txt',
        'lua/meta/reader/README.txt',
        'lua/meta/reader/filename.lua',
        'lua/playlist/README.txt',
        'lua/sd/README.txt',
        'lua/sd/icecast.lua',
        'lua/sd/icast.lua',
        install_dir: docdir_path,
        preserve_path: true,
    )
endif
