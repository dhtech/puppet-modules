# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file


def generate(host, *args):

    mailer_type = 'local'
    relay_host = '[mail.tech.dreamhack.se]'

    for arg in args:
        if arg.startswith('relay'):
            _, relay = arg.split(':', 2)
            relay_host = '[' + relay + ']'

    if 'norelay' in args:
        relay_host = ''

    info = {}
    info['mailer_type'] = mailer_type
    info['relay_host'] = relay_host
    return {'postfix': info}
