# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def generate(host, *args):
  role = args[0]
  ircds = lib.get_nodes_with_package('ircd')
  peers = list()
  for ircd in ircds:
    if role in ircds[ircd]:
      continue
    v4 = lib.resolve_nodes_to_ip((ircd, ))[ircd][0]
    peer = dict()
    peer['fqdn'] = ircd  
    peer['allowmask'] = v4+"/32" 
    peers.append(peer) 
  info = {}
  info['peers'] = peers
  info['sid'] = args[1] 
  return {'inspircd': info}
