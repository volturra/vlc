#!/usr/bin/env python3

# SPDX-License-Identifier: ISC
#
# Print the user and the host building VLC, one per line. The VLC_COMPILE_BY
# and VLC_COMPILE_HOST environment variables override the detected values.

import getpass
import os
import socket


def compile_by():
    try:
        return getpass.getuser()
    except (KeyError, OSError):
        return 'unknown'


def compile_host():
    try:
        return socket.getfqdn() or socket.gethostname()
    except OSError:
        return 'localhost'


print(os.environ.get('VLC_COMPILE_BY') or compile_by())
print(os.environ.get('VLC_COMPILE_HOST') or compile_host())
