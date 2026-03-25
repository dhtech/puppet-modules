# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):
    prometheus_servers = {}
    for server in sorted(lib.get_nodes_with_package('prometheus').keys()):
        try:
            domain = lib.get_domain(server).lower()
        except lib.NoDomainError:
            domain = 'unknown'
        prometheus_servers[server] = domain

    akvorado_servers = {}
    for server in sorted(lib.get_nodes_with_package('akvorado').keys()):
        try:
            domain = lib.get_domain(server).lower()
        except lib.NoDomainError:
            domain = 'unknown'
        akvorado_servers[server] = domain

    info = {
    'grafana': {
        'current_event': lib.get_current_event(),
        'prometheus_servers': prometheus_servers,
        'akvorado_servers': akvorado_servers,
        }
    }

    return info

def requires(host, *args):

    return ['apache(ldap)']

# vim: ts=4: sts=4: sw=4: expandtab
