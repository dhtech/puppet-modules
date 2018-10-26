# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def _generate_client(host):
    info = {}
    servers = lib.get_servers_for_node('ntpd', host)

    # Use local servers if available
    if servers:
        info['servers'] = servers

    return info


def _generate_server(my_os):
    info = {}
    info['servers'] = [
      'ntp1.gbg.netnod.se',
      'ntp1.mmo.netnod.se',
      'ntp1.sth.netnod.se',
      'ntp2.mmo.netnod.se',
      'time4.stupi.se',
    ]
    if my_os == 'openbsd':
        info['server'] = True
    else:
        info['restrict'] = [
             'default limited nomodify notrap nopeer noquery',
             '-6 default limited nomodify notrap nopeer noquery',
             '127.0.0.1',
             '-6 ::1',
             '77.80.128.0 mask 255.255.128.0 limited '
             'kod nomodify notrap nopeer',
             '2001:67c:24d8:: mask ffff:ffff:ffff:: limited '
             'kod nomodify notrap nopeer',
        ]

    return info


def generate(host, *args):

    my_os = lib.get_os(host)

    if 'server' in args:
        info = _generate_server(my_os)
    else:
        info = _generate_client(host)

    # TODO(bluecmd): Write our own NTP module that works for both BSD and Linux
    if my_os == 'openbsd':
        return {'openntpd': info}
    else:
        return {'ntp': info}

# vim: ts=4: sts=4: sw=4: expandtab
