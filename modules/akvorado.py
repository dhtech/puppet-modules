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

def get_sflow_clients():
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
    db.execute(
            "SELECT h.name AS hostname, h.ipv4_addr_txt AS ipv4_addr ,h.ipv6_addr_txt AS ipv6_addr, o2.value AS layer "
            "FROM host h "
            "INNER JOIN option o1 ON h.node_id = o1.node_id "
            "INNER JOIN option o2 ON h.node_id = o2.node_id "
            "WHERE o1.name='pkg' AND o1.value='sflowclient' "
            "AND o2.name='layer'"
            )
    res = db.fetchall()
    if not res:
        return None

    column_names = [description[0] for description in db.description]
    conn.close()
    rows_dict = [dict(zip(column_names, row)) for row in res]

    return rows_dict

def get_snmpv2_providers():
    providers = []
    clients = get_sflow_clients()
    current_event = lib.get_current_event()
    for client in clients:
        key = current_event+'-mgmt/snmp:'+client['layer']
        secrets = lib.read_secret(key)
        if "community" in secrets:
            provider = {
                    "ipv4": client["ipv4_addr"],
                    "community": secrets["community"],
                    }
            providers.append(provider)
    return providers

def get_snmpv3_providers():
    providers = []
    clients = get_sflow_clients()
    current_event = lib.get_current_event()
    for client in clients:
        key = current_event+'-mgmt/snmp:'+client['layer']
        secrets = lib.read_secret(key)
        if "user" in secrets:
            provider = {
                    "ipv4": client["ipv4_addr"],
                    "authentication-passphrase": secrets["auth"],
                    "authentication-protocol": secrets["authtype"].replace(" ","").upper(),
                    "privacy-passphrase": secrets["priv"],
                    "privacy-protocol": secrets["privtype"].replace(" ","").replace("128","").upper(),
                    "user": secrets["user"],
                    }
            providers.append(provider)
    return providers

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
            ' AND NOT (name = "BOGAL@DREAMHACK" AND ipv6_txt = "2a05:2240:5000::/48")'
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


def requires(host, *args):
    return ['apache(ldap)']


def generate(host, *args):

    info = {}
    info['snmpv3_providers'] = get_snmpv3_providers()
    info['snmpv2_providers'] = get_snmpv2_providers()
    info['current_event'] = lib.get_current_event()
    info['ipv6_prefixes'] = get_prefixes('6')
    info['ipv4_prefixes'] = get_prefixes('4')
    return {'akvorado': info}
