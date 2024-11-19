# Copyright 2024 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file

import lib
import sqlite3
import os


DB_FILE = '/etc/ipplan.db'

def ip_to_int(ip):
    """Convert an IPv4 address to an integer."""
    parts = map(int, ip.split('.'))
    return (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]

def int_to_ip(integer):
    """Convert an integer to an IPv4 address."""
    return '.'.join(map(str, [(integer >> 24) & 255, (integer >> 16) & 255, (integer >> 8) & 255, integer & 255]))


def generate(host, *args):  
    # Get current event, used to get up-to-date switch conf
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

    netmask = res[0]

    db.execute('SELECT ipv4_gateway_txt FROM network WHERE short_name = "TECH-WIREGUARD-VPN";')
    res = db.fetchone()
    conn.close()
    if not res:
        raise NodeNotFoundError('Node %s not found' % host)
    
    gatewayip = res[0]


    #tunnelip = int_to_ip(gatewayip + 4)
    
    tunnelip = '77.80.229.133/25'
    
    info = {}
    info['current_event'] = current_event
    info['tunnelip'] = tunnelip
    return {'wireguard': info}

# vim: ts=4: sts=4: sw=4: expandtab
