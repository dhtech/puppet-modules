# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host):
    info = {}

    resolvers = lib.get_servers_for_node('eventdns', host)
    ips = lib.resolve_nodes_to_ip(resolvers)
    info['nameservers'] = [ips[x][0] for x in resolvers]

    info['icmp_target'] = 'ping.sunet.se'
    info['dns_target'] = 'slashdot.org'

    return {'observer': info}

# vim: ts=4: sts=4: sw=4: expandtab
