# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host):
    my_domain = lib.get_domain(host)

    # Only run promtail on event servers
    if not my_domain == 'EVENT':
        return {}

    loki_servers = lib.get_servers_for_node('loki', host)
    if len(loki_servers) == 0:
        # If no loki servers are configured, do not setup promtail
        return {}

    def build_uri(server):
        return "http://{}:3100/loki/api/v1/push".format(server)

    info = {}
    info['loki_uris'] = map(build_uri, loki_servers)
    return {'promtail': info}

# vim: ts=4: sts=4: sw=4: expandtab
