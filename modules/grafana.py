# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):
<<<<<<< HEAD
    info = {
    'grafana': {
        'current_event': lib.get_current_event()
        }
    }
=======
    info = {'current_event': lib.get_current_event()}
>>>>>>> 8027f9d115f4dc65ca389cc4f648c6d6584e28ba

    return info

def requires(host, *args):

    return ['apache(ldap)']

# vim: ts=4: sts=4: sw=4: expandtab
