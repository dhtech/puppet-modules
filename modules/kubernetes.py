# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def generate(host, *args):
    info = {}

    if 'worker' in args:
        if lib.get_domain(host) == 'EVENT':
            info['kubernetes::install'] = {}
            info['kubernetes::worker'] = {
                    'current_event': lib.get_current_event()
            }
        else:
            info['kubernetes::install'] = {}
            #TODO(ventris): check if STO2 or BOGAL to the right keys
            #info['kubernetes::worker']
    if 'master' in args:
        info['kubernetes::install'] = {}
        info['kubernetes::master'] = {}
    if 'colo' in args:
        info['colo_k8s'] = {}
    else:
        info['colo_k8s'] = {}

    return info
