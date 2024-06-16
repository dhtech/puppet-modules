# vim: ts=4: sts=4: sw=4: expandtab
# Copyright 2024 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib
import os
import sqlite3
import yaml

DB_FILE = '/etc/ipplan.db'

def get_prefixes(ipversion):
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

    if ipversion == "4":
        db.execute(
            'SELECT SUBSTR(name,1, INSTR(name, "@")-1), name, short_name, ipv4_txt'
            ' FROM network'
            ' WHERE node_id NOT IN (SELECT option.node_id from option where name = "NO-AKV") and name like "%@%" and ipv4_txt is not NULL'
            )

    elif ipversion == "6":
        db.execute(
            'SELECT SUBSTR(name,1, INSTR(name, "@")-1), name, short_name, ipv6_txt'
            ' FROM network'
            ' WHERE node_id NOT IN (SELECT option.node_id from option where name = "NO-AKV") and name like "%@%" and ipv6_txt is not NULL'
            )
    else:
        raise NetworkTypeNotFoundError('network type must be 4 or 6')

    res = db.fetchall()
    conn.close()
    if not res:
        raise NetworkNotFoundError('network not found')

    return res


def generate(host, *args):

    info = {}
    info['current_event'] = lib.get_current_event()
    info['ipv6_prefixes'] = get_prefixes('6')
    info['ipv4_prefixes'] = get_prefixes('4')
    print(info)
    return {'akverado': info}

