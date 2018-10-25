# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):
    syslog_servers = lib.get_servers_for_node('syslogd', host)

    info = {}
    info['syslog_servers'] = list(syslog_servers) + list(args)
    return {'syslog': info}
