# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib
import grp


def generate(host, *args):
    info = {}
    # get admins from ldap for usage in factorio as admins
    info['admins'] = sorted(grp.getgrnam('factorio-admin-access').gr_mem)
    # see if we have a group password for factorio, otherwise create it
    if lib.get_domain(host) == 'EVENT':
        event = lib.get_current_event()
        secretpath = '{}-mgmt/factorio:{}'.format(event, host)
    else:
        secretpath = 'secrets/factorio:{}'.format(host)

    secrets = lib.read_secret(secretpath)
    if not secrets:
        password = 'kalle'
        res = lib.save_secret(secretpath, password=password)
        secrets = {'password': password}

    info['password'] = secrets['password']
    info['world_name'] = args[0]

    return {'factorio': info}

# vim: ts=4: sts=4: sw=4: expandtab
