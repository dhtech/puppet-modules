# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file


def requires(host, *args):
    return ['dhmon(backend)']

def generate(host, *args):
    return {'prometheus': {}}

# vim: ts=4: sts=4: sw=4: expandtab: