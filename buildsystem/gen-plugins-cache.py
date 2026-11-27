#!/usr/bin/env python3

# SPDX-License-Identifier: ISC
#
# Meson install script: generate the plugins cache of the installed tree.
#
# Usage: gen-plugins-cache.py <pkglibexecdir> <libdir> <pkglibdir> <pluginsdir>
# with absolute directories, which are looked up under DESTDIR when it is set.

import os
import subprocess
import sys


def installed(path):
    destdir = os.environ.get('DESTDIR')
    if not destdir:
        return path
    return os.path.join(destdir, os.path.relpath(path, os.path.abspath(os.sep)))


def main():
    pkglibexecdir, libdir, pkglibdir, pluginsdir = (
        installed(d) for d in sys.argv[1:5])

    cache_gen = os.path.join(pkglibexecdir, 'vlc-cache-gen')
    if not os.path.exists(cache_gen):
        sys.exit(f'{cache_gen} is not installed: no plugins cache generated')

    env = dict(os.environ)
    env['LD_LIBRARY_PATH'] = os.pathsep.join(
        filter(None, [libdir, pkglibdir, env.get('LD_LIBRARY_PATH')]))

    return subprocess.run([cache_gen, pluginsdir], env=env).returncode


if __name__ == '__main__':
    sys.exit(main())
