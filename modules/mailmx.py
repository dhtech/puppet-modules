# Copyright 2019 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file


def generate(host, *args):

    info = {}
    info['ldap_uri'] = 'ldaps://ldap3.tech.dreamhack.se',
    info['postfix_destinations'] = [
        'localhost',
        'mail.tech.dreamhack.se',
        'tech.dreamhack.se',
        'lists.tech.dreamhack.se',
        'event.dreamhack.se',
    ]
    info['postfix_networks'] = [
        '127.0.0.0/8',
        '[::ffff:127.0.0.0]/104',
        '[::1]/128',
        '77.80.228.128/25',
        '77.80.231.0/24',
    ]
    return {'mailmx': info}

# vim: ts=4: sts=4: sw=4: expandtab
