# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):

    if 'local' in args:
        local = 1
    else:
        local = 0

    private_zones = [
      '10.in-addr.arpa',
      '16.172.in-addr.arpa',
      '17.172.in-addr.arpa',
      '18.172.in-addr.arpa',
      '19.172.in-addr.arpa',
      '20.172.in-addr.arpa',
      '21.172.in-addr.arpa',
      '22.172.in-addr.arpa',
      '23.172.in-addr.arpa',
      '24.172.in-addr.arpa',
      '25.172.in-addr.arpa',
      '26.172.in-addr.arpa',
      '27.172.in-addr.arpa',
      '28.172.in-addr.arpa',
      '29.172.in-addr.arpa',
      '30.172.in-addr.arpa',
      '31.172.in-addr.arpa',
      '168.192.in-addr.arpa',
      'event.dreamhack.local',
    ]

    stub_hosts = lib.get_servers_for_node('resolver', host)

    stub_hosts.sort()

    info = {}
    info['private_zones'] = private_zones
    info['stub_hosts'] = stub_hosts
    info['local'] = local
    return {'unbound': info}
