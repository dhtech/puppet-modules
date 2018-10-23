# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def requires(host, *args):

  return ['postfix','ipplan']

def generate(host, *args):

  current_event = lib.get_current_event()

  proto_map = {
    'ios':      'cisco',
    'nxos':    'cisco-nx',
    'fortios':  'fortigate',
    'iosxr':    'cisco-xr',
    'wlc':      'cisco-wlc',
    'junos':    'juniper'
  }

  router_db_lines = []
  for router in lib.get_nodes_with_option('rncd', 'event'):
    protocol = proto_map[lib.get_os(router)]
    router_db_lines.append('%s;%s;up' % (router, protocol))

  info = {}
  info['current_event'] = current_event
  info['router_db_lines'] = router_db_lines
  return {'rancid': info}
