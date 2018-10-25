# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def requires(host, *args):
    my_os = lib.get_os(host)

    if my_os == 'openbsd':
        return ['pf(%s)' % ','.join(args)]
    else:
        return ['iptables(%s)' % ','.join(args)]
