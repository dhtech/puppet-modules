# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):

    my_domain = lib.get_domain(host)
    ldap_servers = sorted(lib.get_nodes_with_package('ldap', my_domain).keys())

    # Just pick the first LDAP server (lexographically)
    server = ldap_servers[0]
    info = {}
    if 'ldap' in args:
        info['ldap'] = server
    return {'apache': info}
