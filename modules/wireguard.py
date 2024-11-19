# Copyright 2024 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib
import sqlite3
import os


DB_FILE = '/etc/ipplan.db'

def generate(host, *args):

    current_event = lib.get_current_event()

    if os.path.isfile(DB_FILE):
        try:
            conn = sqlite3.connect(DB_FILE)
            db = conn.cursor()
        except sqlite3.Error as e:
            print("An error occurred:", e.args[0])
            sys.exit(2)
    else:
        print("No database file found: %s" % DB_FILE)
        sys.exit(3)

    db.execute('SELECT ipv4_netmask_dec FROM network WHERE short_name = "TECH-WIREGUARD-VPN";')
    res = db.fetchone()
    if not res:
        raise NodeNotFoundError('Node %s not found' % host)

    subnet = res[0]

    db.execute('SELECT ipv4_gateway_txt FROM network WHERE short_name = "TECH-WIREGUARD-VPN";')
    res = db.fetchone()
    conn.close()
    if not res:
        raise NodeNotFoundError('Node %s not found' % host)
    
    gatewayIP = res[0]
    tunnelIP = ipaddress.ip_address(gatewayIP) + 4
    tunnelIP = str(tunnelIP)
    
    info = {}
    info['current_event'] = current_event
    info['tunnelIP'] = tunnelIP
    return {'wireguard': info}

# vim: ts=4: sts=4: sw=4: expandtab
