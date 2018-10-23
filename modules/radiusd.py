# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib

def generate(host, *args):

  access_node_ips = lib.resolve_nodes_to_ip(lib.get_nodes_with_layer('access'))
  dist_node_ips = lib.resolve_nodes_to_ip(lib.get_nodes_with_layer('dist'))
  core_node_ips = lib.resolve_nodes_to_ip(lib.get_nodes_with_layer('core'))
  firewall_node_ips = lib.resolve_nodes_to_ip(lib.get_nodes_with_layer('firewall'))
  partner_node_ips = lib.resolve_nodes_to_ip(lib.get_nodes_with_layer('partner'))

  access_ips = []
  for node, addresses in access_node_ips.iteritems():
      access_ips.append([node, addresses[0]])

  dist_ips = []
  for node, addresses in dist_node_ips.iteritems():
      dist_ips.append([node, addresses[0]])

  core_ips = []
  for node, addresses in core_node_ips.iteritems():
      core_ips.append([node, addresses[0]])

  firewall_ips = []
  for node, addresses in firewall_node_ips.iteritems():
      firewall_ips.append([node, addresses[0]])

  partner_ips = []
  for node, addresses in partner_node_ips.iteritems():
      partner_ips.append([node, addresses[0]])

  info = {}
  info['access_ips'] = access_ips
  info['dist_ips'] = dist_ips
  info['core_ips'] = core_ips
  info['firewall_ips'] = firewall_ips
  info['partner_ips'] = partner_ips
  return {'radiusd': info}
