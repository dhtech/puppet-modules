# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

# TODO(bluecmd):
# To not mess up existing ldap installations, do not run puppet ldap on these:
blacklist = [
        'ldap0.tech.dreamhack.se',
        'ldap1.tech.dreamhack.se',
        'ldap2.tech.dreamhack.se'
]


def generate(host, *args):
    domain = lib.get_domain(host)
    if host in blacklist:
        return {}

    return {'ldap': {'master': args[0]}}
