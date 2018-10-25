# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file


def generate(host, *args):
    hostname_list = []
    for hostname in args:
        hostname_list.append(hostname)

    info = {}
    info['hostname_list'] = hostname_list
    return {'dehydrated': info}
