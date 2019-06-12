# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def generate(host, *args):

    ircbots = sorted(lib.get_nodes_with_package('ircbot', 'event').keys())

    info = {}
    if ircbots:
        info['ircbot'] = ircbots[0]

    return {'rsyslog': info}

# vim: ts=4: sts=4: sw=4: expandtab
