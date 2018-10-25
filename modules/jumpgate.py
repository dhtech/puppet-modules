# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file


def requires(host, *args):
    return ['ipplan']


def generate(host, *args):
    return {'jumpgate': None}
