# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib
import lib.sqlite2dhcp_scope

from socket import AF_INET, inet_ntop
from struct import pack

def requires(host, *args):

  return ['supervisor']

def generate(host, *args):

  # Decide if we are the active node:
  if 'active' in args:
    active = 1;
  else:
    active = 0;

  # Get fqdn of active node
  active_node = 'ddns1.event.dreamhack.se'
  for (k, v) in lib.get_nodes_with_package('dhcpd', lib.get_domain(host)).items():
    if v == [u'active']:
      active_node = k
      break

  # Fetch DHCP scopes
  scopes = lib.sqlite2dhcp_scope.App(
      ['-', '/etc/ipplan.db', '-']).run_from_puppet()

  # Get the subnet the dhcpd lives at in CIDR notation
  local_subnet_cidr = lib.get_ipv4_network(host)[0]
  local_subnet = local_subnet_cidr.split('/')[0]
  local_cidr = int(local_subnet_cidr.split('/')[1])

  # Convert CIDR to netmask
  bitmask = 0xffffffff ^ (1 << 32 - local_cidr) - 1
  local_netmask = inet_ntop(AF_INET, pack('!I', bitmask))

  # Set ntp-servers
  ntp_servers = ", ".join(lib.get_servers_for_node('ntpd', host))
  if not ntp_servers:
    ntp_servers = ('0.pool.ntp.org, '
                   '1.pool.ntp.org, '
                   '2.pool.ntp.org, '
                   '3.pool.ntp.org')

  # Set domain-name-servers
  resolver_ipv4_addresses = []
  for hostname, addresses in lib.resolve_nodes_to_ip(
    lib.get_servers_for_node('resolver', host)).iteritems():

    resolver_ipv4_addresses.append(addresses[0])

  resolver_ipv4_addresses.sort()
  domain_name_servers = ", ".join(resolver_ipv4_addresses)

  if not domain_name_servers:
    domain_name_servers = '8.8.8.8, 8.8.4.4'

  # Set tftp-server-name
  tftp_server_name_address = lib.resolve_nodes_to_ip([
                                               'pxe.event.dreamhack.se'])
  tftp_server_name = tftp_server_name_address['pxe.event.dreamhack.se'][0]

  # Set next-server
  next_server_addresses = lib.resolve_nodes_to_ip(['pxe.event.dreamhack.se'])
  next_server = next_server_addresses['pxe.event.dreamhack.se'][0]

  # Get current event, used to decide name of dhcpinfo database
  current_event = lib.get_current_event()

  info = {}
  info['active'] = active
  info['active_node'] = active_node
  info['scopes'] = scopes
  info['ntp_servers'] = ntp_servers
  info['domain_name_servers'] = domain_name_servers
  info['tftp_server_name'] = tftp_server_name
  info['next_server'] = next_server
  info['local_subnet'] = local_subnet
  info['local_netmask'] = local_netmask
  info['current_event'] = current_event

  return {'dhcpd': info}
