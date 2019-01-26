# Copyright 2019 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import pypuppetdb

def generate(host, *args):
    db = pypuppetdb.connect()
    ssh = db.facts('ssh')
    servers = [{
        'fqdn': x.node,
        'ssh-key': '%s %s' % (x.value['ecdsa']['type'], x.value['ecdsa']['key'])
        } for x in ssh]
    return {'borgserver': {'servers': sorted(servers)}}

# vim: ts=4: sts=4: sw=4: expandtab
