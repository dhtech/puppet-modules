# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):
    # The LDAP master is not really handled by puppet, but let puppet handle
    # the part required for sync monitoring.
    return {'ldapsyncprober': {'trigger_interval': '30'}}
