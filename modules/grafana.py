# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):
    info = {'current_event': lib.get_current_event()}

    return info

def requires(host, *args):

    return ['apache(ldap)']

# vim: ts=4: sts=4: sw=4: expandtab
