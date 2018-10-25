#!/usr/bin/env python2
# coding: utf-8
#
# Copyright (c) 2013-2014, Torbjörn Lönnemark <tobbez@ryara.net>
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#

from __future__ import print_function, unicode_literals

import collections
import ipcalc
import sqlite3
import StringIO
import sys

from collections import defaultdict

# To use this as a library (and not from the command line), you
# can do as follows:
#
# import sqlite2dhcp_scope
# sqlite2dhcp_scope.App(['-', '/path/to/ipplan.db', '-']).run_from_puppet()
#
# which returns the complete dhcp scope as a string.


class App:
    def __init__(self, args):
        if not self._check_args(args):
            self._print_help()
            sys.exit(0)
        ipplan_file, scope_file = args[1:]
        self.db = sqlite3.connect(ipplan_file)

        if scope_file == '-':
            self.out = sys.stdout
        else:
            self.out = open(scope_file, 'w')

    def _check_args(self, args):
        return len(args) == 3 and not ('-h' in args or '--help' in args)

    def _print_help(self):
        print('Usage: {} <ipplan.db> <scopes-file>'.format(__file__))

    def _print_indented(self, text, indent=0):
        self.out.write('\t'*indent + text + '\n')

    def run(self):
        self.gen_scopes()
        self.gen_hosts()

    def run_from_puppet(self):
        self.out = StringIO.StringIO()
        self.run()
        return self.out.getvalue()

    def gen_scopes(self):
        c = self.db.cursor()
        c.execute("""select network.node_id, option2.value
                from network
                inner join option
                    on network.node_id=option.node_id and
                        option.name='dhcp'
                left outer join option as option2
                    on network.node_id=option2.node_id and
                        option2.name='shnet'""")

        single_nets = []
        shared_nets = defaultdict(lambda: [])
        for row in c.fetchall():
            node_id, shnet = row

            if shnet is None:
                single_nets.append(node_id)
            else:
                shared_nets[shnet].append(node_id)

        for sn in single_nets:
            self.gen_subnet(sn)

        for shnet in shared_nets.keys():
            self.gen_shared_network(shnet, shared_nets[shnet])

    def gen_hosts(self):
        c = self.db.cursor()
        c.execute("""select host.name, ipv4_addr_txt, option.value
            from host, option
            where option.name='mac' and host.node_id = option.node_id""")
        host_index = collections.defaultdict(int)
        for row in c.fetchall():
            host, ip, mac = row
            self.gen_host(host, ip, mac, host_index[host])
            host_index[host] += 1

    def gen_host(self, host, ip, mac, index=0):
        self._print_indented('#@ HOST {} - {} - MAC {}'.format(host, ip, mac))
        self._print_indented('host {}-{} {{'.format(host, index))
        self._print_indented('hardware ethernet {};'.format(mac), 1)
        self._print_indented('fixed-address {};'.format(ip), 1)
        self._print_indented('}\n')

    def gen_subnet(self, subnet_id, indent=0):
        """Generates config for one subnet"""

        c = self.db.cursor()
        c.execute('SELECT name, vlan, ipv4_txt, ipv4_netmask_txt, '
                  'ipv4_gateway_txt FROM network '
                  'WHERE node_id=?', (subnet_id,))
        name, vlan, ip_cidr, netmask, gateway = c.fetchone()
        ip = ip_cidr.split('/')[0]

        c.execute("""SELECT value FROM option WHERE '
                  'name='resv' AND node_id=?""", (subnet_id,))
        resv_rows = c.fetchall()
        resv = 5  # default value
        if len(resv_rows) > 0:
            resv = int(resv_rows[0][0])

        net = ipcalc.Network(ip_cidr)
        range_start = ipcalc.IP(int(net.host_first())+resv)
        range_end = net.host_last()

        c.execute("""SELECT name, value FROM option
            WHERE node_id=? AND name LIKE 'dhcp-%'""", (subnet_id,))
        options = dict(map(lambda x: (x[0][5:], x[1]), c.fetchall()))

        self._print_indented('#@ NET {} {} - VLAN {}'
                             .format(name, ip_cidr, vlan), indent)
        self._print_indented('subnet {} netmask {} {{'
                             .format(ip, netmask), indent)
        self._print_indented('range {} {};'
                             .format(range_start, range_end), indent+1)
        self._print_indented('option routers {};'.format(gateway), indent+1)

        if 'tftp' in options:
            host = options['tftp']
            c = self.db.cursor()
            c.execute('SELECT ipv4_addr_txt FROM '
                      'host WHERE name = ?', (host, ))
            ipv4, = c.fetchone()
            self._print_indented('filename "/tftpboot.img";', indent+1)
            self._print_indented('next-server {};'.format(ipv4), indent+1)
            del options['tftp']

        for option in options.iteritems():
            self._print_indented('{} {};'.format(*option), 1)

        self._print_indented('}\n', indent)

    def gen_shared_network(self, shnet, subnets):
        """Generates a shared network block"""

        self._print_indented('#@ SHARED-NET {}'.format(shnet))
        self._print_indented('shared-network shared-net-{} {{'.format(shnet))

        for sn in subnets:
            self.gen_subnet(sn, 1)

        self._print_indented('}\n')


if __name__ == '__main__':
    App(sys.argv).run()
