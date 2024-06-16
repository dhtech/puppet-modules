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
            print("An error occurred: {}".format(e.args[0]))
            exit(2)
    else:
        print("No database file found: {}".format(DB_FILE))
        exit(3)

    if ipversion == "4":
        db.execute(
            'SELECT SUBSTR(name,1, INSTR(name, "@")-1) AS location, name, short_name, ipv4_txt'
            ' FROM network'
            ' WHERE node_id NOT IN (SELECT option.node_id FROM option WHERE name = "no-akv")'
            ' AND name LIKE "%@%" AND ipv4_txt IS NOT NULL'
            )

    elif ipversion == "6":
        db.execute(
            'SELECT SUBSTR(name,1, INSTR(name, "@")-1) AS location, name, short_name, ipv6_txt'
            ' FROM network'
            ' WHERE node_id NOT IN (SELECT option.node_id FROM option WHERE name = "no-akv")'
            ' AND name LIKE "%@%" AND ipv6_txt IS NOT NULL'
            )
    else:
        raise NetworkTypeNotFoundError('network type must be 4 or 6')

    res = db.fetchall()
    if not res:
        raise NetworkNotFoundError('network not found')

    column_names = [description[0] for description in db.description]
    conn.close()
    rows_dict = [dict(zip(column_names, row)) for row in res]

    return rows_dict


def generate(host, *args):

    info = {}
    info['current_event'] = lib.get_current_event()
    info['ipv6_prefixes'] = get_prefixes('6')
    info['ipv4_prefixes'] = get_prefixes('4')
    return {'akverado': info}
