# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def generate(host, *args):

    ircbots = sorted(lib.get_nodes_with_package('ircbot', 'event').keys())

    info = {}
    if 'rsyslog' in args:
        if ircbots:
            info['rsyslog'] = {'ircbot': ircbots[0]}
        else
            info['rsyslog'] = {}

    return info

# vim: ts=4: sts=4: sw=4: expandtab
