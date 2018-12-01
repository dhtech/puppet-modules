# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):
    my_domain = lib.get_domain(host)

    info = {}

    my_dns_domain = '.'.join(host.split('.')[1:])

    info['domain'] = my_dns_domain

    # Some things (busybox? musl?) doesn't work well with multiple searchs.
    # Let's use only the primary one for now
    info['search'] = [my_dns_domain]

    if my_domain == 'EVENT':
        resolvers = lib.get_servers_for_node('eventdns', host)
    else:
        resolvers = lib.get_servers_for_node('dns', host)

    # Sort to lexographical order (e.g. ddns1 before ddns3)
    resolvers = sorted(resolvers)

    info['nameservers'] = []

    # Do not use ourself if we are a resolver.
    if host in resolvers:
        resolvers.remove(host)
        # Use an external resolver by default so we do not create deadlocks
        # when bootstrapping the environment from scratch.
        info['nameservers'].append('1.1.1.1')

    ips = lib.resolve_nodes_to_ip(resolvers)
    info['nameservers'].extend([ips[x][0] for x in resolvers])

    # Default to Google DNS
    info['nameservers'].extend(['8.8.8.8', '8.8.4.4'])

    # Only three, no support for more in Linux
    info['nameservers'] = info['nameservers'][:3]
    return {'resolvconf': info}

# vim: ts=4: sts=4: sw=4: expandtab
