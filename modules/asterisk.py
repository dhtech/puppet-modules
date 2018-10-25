# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):
    current_event = lib.get_current_event()
    info = {}
    info['current_event'] = current_event

    return {'asterisk': info}
