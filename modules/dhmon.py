# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def requires(host, *args):
    return ['apache(ldap)']


def generate(host, *args):
    info = {}

    local_targets = []

    if 'web' in args:
        info['dhmon::analytics'] = {}
        info['dhmon::web'] = {}
        }

    return info

# vim: ts=4: sts=4: sw=4: expandtab
