# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib
import os
import sqlite3
import re

DB_FILE = '/etc/ipplan.db'


def get_domain(host):
    if os.path.isfile(DB_FILE):
        try:
            conn = sqlite3.connect(DB_FILE)
            db = conn.cursor()
        except sqlite3.Error as e:
            print "An error occurred:", e.args[0]
            sys.exit(2)
    else:
        print "No database file found: %s" % DB_FILE
        sys.exit(3)

    db.execute(
      'SELECT n.name FROM host h, network n WHERE h.network_id = n.node_id '
      'AND h.name = ?', (host, ))
    res = db.fetchone()
    conn.close()
    if not res:
        raise NodeNotFoundError('Node %s not found' % host)

    network = res[0]

    if '@' not in network:
        raise NoDomainError('Node %s belongs to network %s which has no domain'
                            % (host, network))

    return network.split('@')[0]


def generate(host, *args):
    allowed_hosts = ['::1/128']
    for r in lib.get_firewall_rules_to(host):
        if r.service == 'pgdb':
            ipv4 = r.from_ipv4
            if '/' not in ipv4:
                ipv4 += '/32'
            ipv6 = r.from_ipv6
            if '/' not in ipv6:
                ipv6 += '/128'
            allowed_hosts.append(ipv4)
            allowed_hosts.append(ipv6)

    # Check first option for version
    version = None
    if len(args) > 0:
        m = re.match(r'^v(\d+)$', args[0])
        if m is not None:
            del args[0]
            version = m.group(1)

    if version is None:
        raise Exception('No or invalid version for PostgreSQL specified')

    # Read list of database to create on this server
    db_list = []
    for arg in args:
        db_list.append(arg)

    current_event = lib.get_current_event()

    info = {}
    info['allowed_hosts'] = sorted(x.ljust(46) for x in allowed_hosts)
    info['db_list'] = db_list
    info['current_event'] = current_event
    info['domain'] = get_domain(host)
    info['version'] = version

    return {'postgresql': info}

# vim: ts=4: sts=4: sw=4: expandtab
