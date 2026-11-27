#!/bin/sh
# Native Fedora build of VLC with its build dependencies kept in a toolbox
# container, so only the runtime libraries are needed on the host.
#
# Usage: extras/toolbox/vlc-toolbox.sh <command> [args...]
#   create              create the toolbox and install the build dependencies
#   setup [meson args]  configure build-native/ (wipes an existing one)
#   build               ninja -C build-native
#   test [meson args]   meson test -C build-native
#   install             install to $PREFIX, link bin/vlc and add a desktop entry
#   uninstall           remove what install added
#   shell               enter the toolbox
#   destroy             remove the toolbox and every build dependency with it
#
# PREFIX defaults to ~/.local/opt/vlc. The binaries carry an rpath to it, and
# run on the host directly, using the host's libraries, GPU and display.

set -e

SRCDIR=$(cd "$(dirname "$0")/../.." && pwd)
BUILDDIR=${VLC_TOOLBOX_BUILDDIR:-build-native}
BOX=${VLC_TOOLBOX_NAME:-vlc-dev}
PREFIX=${PREFIX:-$HOME/.local/opt/vlc}
DATAHOME=${XDG_DATA_HOME:-$HOME/.local/share}
BINHOME=$HOME/.local/bin

. /etc/os-release
RELEASE=${VLC_TOOLBOX_RELEASE:-$VERSION_ID}

PACKAGES="
    gcc gcc-c++ meson ninja-build flex bison pkgconf-pkg-config gettext-devel lua
    desktop-file-utils
    ffmpeg-devel libplacebo-devel libva-devel libvdpau-devel nv-codec-headers
    libdrm-devel mesa-libGL-devel mesa-libEGL-devel mesa-libgbm-devel vulkan-loader-devel
    libX11-devel libxcb-devel xcb-util-keysyms-devel libxkbcommon-devel libxkbcommon-x11-devel
    libXpm-devel libXinerama-devel libXcursor-devel
    wayland-devel wayland-protocols-devel
    qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtsvg-devel
    qt6-qtshadertools-devel qt6-qt5compat-devel qt6-qtwayland-devel
    pipewire-devel pulseaudio-libs-devel alsa-lib-devel
    pipewire-jack-audio-connection-kit-devel
    freetype-devel fribidi-devel harfbuzz-devel fontconfig-devel libass-devel
    libpng-devel libjpeg-turbo-devel librsvg2-devel zvbi-devel
    libkate-devel aribb24-devel libaribcaption-devel
    libgcrypt-devel gnutls-devel libxml2-devel lua-devel taglib-devel
    libidn2-devel libssh2-devel libnfs-devel srt-devel
    libsmbclient-devel libupnp-devel libmtp-devel live555-devel libshout-devel
    protobuf-devel libmicrodns-devel libvncserver-devel
    libebml-devel libmatroska-devel libdvbpsi-devel
    libdav1d-devel libaom-devel libvpx-devel x264-devel x265-devel
    libmpeg2-devel faad2-devel mpg123-devel libmad-devel twolame-devel
    flac-devel libvorbis-devel opus-devel speex-devel speexdsp-devel
    libogg-devel libtheora-devel libsamplerate-devel soxr-devel
    libmodplug-devel game-music-emu-devel fluidsynth-devel
    libebur128-devel rnnoise-devel libchromaprint-devel
    libarchive-devel libdvdnav-devel libdvdread-devel libbluray-devel
    libprojectM-devel
    libsecret-devel dbus-devel libnotify-devel
    ncurses-devel libcaca-devel
"
# A plugin whose runtime library is missing on the host is skipped when VLC
# starts: install that library's package on the host to use the plugin.

inbox() {
    toolbox run -c "$BOX" sh -c 'cd "$1" && shift && exec "$@"' sh "$SRCDIR" "$@"
}

RPATH="-Wl,-rpath,$PREFIX/lib64"

setup() {
    WIPE=
    [ -f "$BUILDDIR/build.ninja" ] && WIPE=--wipe
    inbox meson setup $WIPE "$BUILDDIR" \
        --prefix "$PREFIX" --buildtype debugoptimized \
        -Dc_link_args="$RPATH" -Dcpp_link_args="$RPATH" \
        "$@"
}

# VLC's desktop entries and icons in the data directory $1, relative to it
data_files() {
    {
        for f in vlc vlc-openbd vlc-opendvd vlc-openvcd vlc-opencda; do
            echo "applications/$f.desktop"
        done
        for size in 16 32 48 128 256; do
            for icon in vlc vlc-xmas vlc-aprilfools vlc-kb; do
                echo "icons/hicolor/${size}x$size/apps/$icon.png"
                echo "icons/hicolor/${size}x$size/apps/$icon.xpm"
            done
        done
    } | while read -r f; do
        if [ -f "$1/$f" ]; then
            echo "$f"
        fi
    done
}

desktop_files() {
    data_files "$PREFIX/share" | while read -r f; do
        mkdir -p "$DATAHOME/$(dirname "$f")"
        cp "$PREFIX/share/$f" "$DATAHOME/$f"
    done
    update-desktop-database -q "$DATAHOME/applications" 2>/dev/null || true
    gtk-update-icon-cache -q -t "$DATAHOME/icons/hicolor" 2>/dev/null || true
}

cmd=${1:-build}
[ $# -gt 0 ] && shift

case "$cmd" in
    create)
        toolbox list -c | grep -qw "$BOX" || toolbox create -y --distro fedora --release "$RELEASE" "$BOX"
        # ffmpeg-devel and x26x come from RPM Fusion, like the host's ffmpeg-libs
        inbox sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$RELEASE.noarch.rpm"
        inbox sudo dnf install -y --allowerasing $PACKAGES
        ;;
    setup)
        setup "$@"
        ;;
    build)
        [ -f "$BUILDDIR/build.ninja" ] || setup
        inbox ninja -C "$BUILDDIR" "$@"
        ;;
    test)
        inbox meson test -C "$BUILDDIR" --print-errorlogs "$@"
        ;;
    install)
        inbox meson install -C "$BUILDDIR" --quiet
        # Describe the plugins as they load with the host's libraries
        "$PREFIX/libexec/vlc/vlc-cache-gen" "$PREFIX/lib64/vlc/plugins"
        mkdir -p "$BINHOME"
        for b in vlc cvlc rvlc qvlc svlc nvlc; do
            [ -e "$PREFIX/bin/$b" ] && ln -sf "$PREFIX/bin/$b" "$BINHOME/$b"
        done
        desktop_files
        echo "installed to $PREFIX"
        ;;
    uninstall)
        for b in vlc cvlc rvlc qvlc svlc nvlc; do
            [ "$(readlink "$BINHOME/$b")" = "$PREFIX/bin/$b" ] && rm -f "$BINHOME/$b"
        done
        data_files "$DATAHOME" | while read -r f; do
            rm -f "$DATAHOME/$f"
        done
        rm -rf "$PREFIX"
        update-desktop-database -q "$DATAHOME/applications" 2>/dev/null || true
        ;;
    shell)
        toolbox enter "$BOX"
        ;;
    destroy)
        toolbox rm -f "$BOX"
        ;;
    *)
        sed -n '5,14p' "$0" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
