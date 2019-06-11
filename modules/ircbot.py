# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file


def generate(host, *args):

    ircds = sorted(lib.get_nodes_with_package('ircd', 'event').keys())

    info = {}
    if ircds:
        info['ircserver'] = ircds[0]
    info['admins'] = sorted(grp.getgrnam('ircbot-admin-access').gr_mem)

    return {'ircbot': info}

# vim: ts=4: sts=4: sw=4: expandtab
