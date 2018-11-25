# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):

    info = {}
    info['etcd::install'] = {}
    etcd = []
    for h, o in lib.get_nodes_with_package("etcd").items():
        if variant in o:
            etcd.append(h)
    info['etcd::init'] = {
        'variant': args[0],
        'nodes': etcd
    }

    return info