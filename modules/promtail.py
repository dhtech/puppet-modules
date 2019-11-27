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

    loki = {
        "protocol": "https",
        "hostname": lib.get_servers_for_node('loki', host)[0],
        "port": 3100,
        "path": "/loki/api/v1/push",
    }

    info = {}
    info['loki_uri'] = '{protocol}://{hostname}:{port}{path}'.format(**loki)
    return {'snmpexporter': info}

# vim: ts=4: sts=4: sw=4: expandtab
