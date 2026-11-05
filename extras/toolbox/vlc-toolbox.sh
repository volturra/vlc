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
    ffmpeg-devel libplacebo-devel libva-devel libvdpau-devel nv-codec-headers
    libdrm-devel mesa-libGL-devel mesa-libEGL-devel mesa-libgbm-devel vulkan-loader-devel
    libX11-devel libxcb-devel xcb-util-keysyms-devel libxkbcommon-devel libxkbcommon-x11-devel
    wayland-devel wayland-protocols-devel
    qt6-qtbase-devel qt6-qtbase-private-devel qt6-qtdeclarative-devel qt6-qtsvg-devel
    qt6-qtshadertools-devel qt6-qt5compat-devel qt6-qtwayland-devel
    pipewire-devel pulseaudio-libs-devel alsa-lib-devel
    freetype-devel fribidi-devel harfbuzz-devel fontconfig-devel libass-devel
    libpng-devel libjpeg-turbo-devel zvbi-devel
    libgcrypt-devel gnutls-devel libxml2-devel lua-devel taglib-devel
    libssh2-devel libnfs-devel srt-devel
    libebml-devel libmatroska-devel libdav1d-devel libvpx-devel x264-devel x265-devel
    libmpeg2-devel faad2-devel mpg123-devel flac-devel libvorbis-devel opus-devel
    libogg-devel libtheora-devel libsamplerate-devel soxr-devel
    libarchive-devel libdvdnav-devel libdvdread-devel libbluray-devel
    libsecret-devel dbus-devel libnotify-devel
"
# Not installed: they would be linked in but their runtime libraries are not
# on a stock Fedora desktop (libidn would even be linked into libvlccore).
# Install the runtime package on the host first to add one back.
#   libidn-devel libupnp-devel libmad-devel speexdsp-devel

inbox() {
    toolbox run -c "$BOX" sh -c 'cd "$1" && shift && exec "$@"' sh "$SRCDIR" "$@"
}

# lib64/vlc holds private libraries used by some plugins
RPATH="-Wl,-rpath,$PREFIX/lib64:$PREFIX/lib64/vlc"

setup() {
    WIPE=
    [ -f "$BUILDDIR/build.ninja" ] && WIPE=--wipe
    inbox meson setup $WIPE "$BUILDDIR" \
        --prefix "$PREFIX" --buildtype debugoptimized \
        -Dc_link_args="$RPATH" -Dcpp_link_args="$RPATH" \
        "$@"
}

desktop_files() {
    mimetypes=$(sed 's/\s*#.*$//g' "$SRCDIR/share/vlc.desktop.mimetypes" | grep -v '^$' | tr '\n' ';')
    mkdir -p "$DATAHOME/applications"
    for f in vlc vlc-openbd vlc-opendvd vlc-openvcd vlc-opencda; do
        sed -e "s|@bindir@|$PREFIX/bin|g" -e "s|@MIMETYPES@|$mimetypes|g" \
            "$SRCDIR/share/$f.desktop.in" > "$DATAHOME/applications/$f.desktop"
    done
    for size in 16 32 48 128 256; do
        mkdir -p "$DATAHOME/icons/hicolor/${size}x$size/apps"
        cp "$SRCDIR/share/icons/${size}x$size/vlc.png" "$DATAHOME/icons/hicolor/${size}x$size/apps/vlc.png"
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
        # The cache copied from the build tree is stale once installed
        "$PREFIX/libexec/vlc/vlc-cache-gen" "$PREFIX/lib64/vlc/plugins"
        mkdir -p "$BINHOME"
        for b in vlc cvlc rvlc qvlc nvlc; do
            [ -e "$PREFIX/bin/$b" ] && ln -sf "$PREFIX/bin/$b" "$BINHOME/$b"
        done
        desktop_files
        echo "installed to $PREFIX"
        ;;
    uninstall)
        for b in vlc cvlc rvlc qvlc nvlc; do
            [ "$(readlink "$BINHOME/$b")" = "$PREFIX/bin/$b" ] && rm -f "$BINHOME/$b"
        done
        for f in vlc vlc-openbd vlc-opendvd vlc-openvcd vlc-opencda; do
            rm -f "$DATAHOME/applications/$f.desktop"
        done
        for size in 16 32 48 128 256; do
            rm -f "$DATAHOME/icons/hicolor/${size}x$size/apps/vlc.png"
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
