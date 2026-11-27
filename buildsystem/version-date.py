#!/usr/bin/env python3

# SPDX-License-Identifier: ISC
#
# Print the release date of the source tree given as first argument: the date
# of the annotated version tag pointing at HEAD, or the current date.

import datetime
import os
import re
import subprocess
import sys

VERSION_PATTERN = re.compile(r'^v?([0-9]+\.?)+(-[0-9]+)?$')


def git(srcdir, *args):
    try:
        result = subprocess.run(['git', '-C', srcdir, *args],
                                capture_output=True, text=True)
    except OSError:
        return ''
    return result.stdout if result.returncode == 0 else ''


def main():
    srcdir = sys.argv[1]
    date = ''
    tags = git(srcdir, 'tag', '--points-at', 'HEAD',
               '--sort=-version:refname').splitlines()
    tags = [tag for tag in tags if VERSION_PATTERN.match(tag)]
    if tags:
        date = git(srcdir, 'for-each-ref', '--format=%(taggerdate:short)',
                   'refs/tags/' + tags[0]).strip()
        if not date and os.environ.get('TAG'):
            sys.exit('Building with the TAG environment variable set but '
                     f'the {tags[0]} tag has no date: it must be annotated')
    print(date or datetime.date.today().isoformat())


if __name__ == '__main__':
    main()
