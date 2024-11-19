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

    tunnelip = '77.80.229.133/25'
    
    info = {}
    info['current_event'] = current_event
    info['tunnelip'] = tunnelip
    return {'wireguard': info}

# vim: ts=4: sts=4: sw=4: expandtab
