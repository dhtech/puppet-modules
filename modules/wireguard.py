# Copyright 2024 dhtech
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file

import lib
import sqlite3
import os
import ipcalc
import sys

DB_FILE = '/etc/ipplan.db'

def generate(host, *args):
    netmask, gatewayip = None, None
    info = {}

    # Get current event
    current_event = lib.get_current_event()

    if os.path.isfile(DB_FILE):
        try:
            conn = sqlite3.connect(DB_FILE)
            db = conn.cursor()
        except sqlite3.Error:
            info['current_event'] = current_event
            info['tunnelip'] = tunnelip
            return {'wireguard': info}
    else:
        info['current_event'] = current_event
        info['tunnelip'] = tunnelip
        return {'wireguard': info}

    db.execute('SELECT ipv4_netmask_dec, ipv4_gateway_txt FROM network WHERE short_name = "TECH-WIREGUARD-VPN";')
    res = db.fetchone()
    conn.close()

    if res:
        netmask, gatewayip = res
        tunnelip = ipcalc.IP(gatewayip) + 4
        tunnelip = str(tunnelip) + '/' + str(netmask)
    else:
        netmask, gatewayip = None, None

    info = {}
    info['current_event'] = current_event
    info['tunnelip'] = tunnelip
    return {'wireguard': info}

# vim: ts=4: sts=4: sw=4: expandtab