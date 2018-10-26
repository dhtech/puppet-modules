# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):
    root_ca = lib.read_secret('ca-pki/cert/ca')
    return {'system': {'ca': root_ca['certificate']}}

# vim: ts=4: sts=4: sw=4: expandtab
