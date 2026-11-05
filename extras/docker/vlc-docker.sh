#!/bin/sh
# Build and run VLC inside the upstream CI image (registry.videolan.org/vlc-debian-unstable).
#
# Usage: extras/docker/vlc-docker.sh <command> [args...]
#   setup [meson args]  configure build-docker/ (wipes an existing one)
#   build               ninja -C build-docker
#   test [meson args]   meson test -C build-docker
#   run [vlc args]      run the built vlc (bin/vlc-static) with the host display and audio
#   shell               interactive shell in the container
#
# The source tree is mounted at the same path as on the host, so paths in
# build-docker/compile_commands.json are valid on the host too.

set -e

SRCDIR=$(cd "$(dirname "$0")/../.." && pwd)
BUILDDIR=${VLC_DOCKER_BUILDDIR:-build-docker}

# Follow the image pinned by upstream CI
IMAGE=${VLC_DOCKER_IMAGE:-$(sed -n 's/^ *VLC_DEBIAN_IMAGE: *//p' "$SRCDIR/extras/ci/gitlab-ci.yml")}
[ -n "$IMAGE" ] || { echo "cannot find VLC_DEBIAN_IMAGE in extras/ci/gitlab-ci.yml" >&2; exit 1; }

if command -v podman >/dev/null 2>&1; then
    ENGINE=podman
    # Map the image's videolan user (499) to the host user so files stay ours
    USEROPT="--userns=keep-id:uid=499,gid=499"
else
    ENGINE=docker
    USEROPT="--user $(id -u):$(id -g)"
fi

TTYOPT=
[ -t 0 ] && [ -t 1 ] && TTYOPT=-it

container() {
    # label=disable avoids recursively relabelling the whole tree on SELinux hosts
    $ENGINE run --rm $TTYOPT $USEROPT \
        --security-opt label=disable \
        -v "$SRCDIR:$SRCDIR" -w "$SRCDIR" \
        -e HOME=/tmp \
        "$@"
}

cmd=${1:-build}
[ $# -gt 0 ] && shift

case "$cmd" in
    setup)
        WIPE=
        [ -f "$BUILDDIR/build.ninja" ] && WIPE=--wipe
        container "$IMAGE" meson setup $WIPE "$BUILDDIR" "$@"
        ;;
    build)
        [ -f "$BUILDDIR/build.ninja" ] || container "$IMAGE" meson setup "$BUILDDIR"
        container "$IMAGE" ninja -C "$BUILDDIR" "$@"
        ;;
    test)
        container "$IMAGE" meson test -C "$BUILDDIR" --print-errorlogs "$@"
        ;;
    run)
        XDG=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
        set -- -e XDG_RUNTIME_DIR=/tmp/xdg -v "$XDG:/tmp/xdg" \
            -e WAYLAND_DISPLAY -e DISPLAY -e QT_QPA_PLATFORM \
            -e PULSE_SERVER=unix:/tmp/xdg/pulse/native \
            -v /tmp/.X11-unix:/tmp/.X11-unix \
            --device /dev/dri "$IMAGE" \
            "$SRCDIR/$BUILDDIR/bin/vlc-static" "$@"
        container "$@"
        ;;
    shell)
        container "$IMAGE" bash
        ;;
    *)
        sed -n '4,10p' "$0" | sed 's/^# \{0,1\}//'
        exit 1
        ;;
esac
