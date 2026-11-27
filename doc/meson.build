# Manual pages and documentation

if host_system == 'windows'
    subdir_done()
endif

install_man('vlc.1', 'vlc-wrapper.1')

install_data('fortunes.txt', install_dir: docdir_path)

install_data(
    'libvlc/gtk_player.c',
    'libvlc/QtPlayer/LICENSE',
    'libvlc/QtPlayer/main.cpp',
    'libvlc/QtPlayer/player.cpp',
    'libvlc/QtPlayer/player.h',
    'libvlc/QtPlayer/QtVLC.pro',
    'libvlc/QtGL/main.cpp',
    'libvlc/QtGL/qtvlcwidget.cpp',
    'libvlc/QtGL/qtvlcwidget.h',
    'libvlc/QtGL/QtGl.pro',
    'libvlc/thumbnailer.c',
    'libvlc/wx_player.cpp',
    'libvlc/d3d11_player.cpp',
    'libvlc/d3d9_player.c',
    'libvlc/win_player.c',
    'libvlc/CMakeLists.txt',
    'libvlc/appkit_player.m',
    'libvlc/downloader.c',
    'libvlc/parser.c',
    'libvlc/media_discoverer.c',
    'libvlc/renderer_discoverer.c',
    'libvlc/player.c',
    install_dir: docdir_path,
    preserve_path: true,
)
