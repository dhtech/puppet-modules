# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file


def generate(host, *args):
    info = {}
    if 'rsyslog' in args:
        info['rsyslog'] = {}
    return info

# vim: ts=4: sts=4: sw=4: expandtab
