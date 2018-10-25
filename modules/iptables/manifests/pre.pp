# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# Initial iptables rules that always applies

class iptables::pre ($forward_policy = 'drop') {

  # This is apparently needed in order to not have puppet find made-up
  # cycles in the dependency graph
  Firewall {
    require => undef,
  }

  # Default firewall rules
  firewall {
    '000 v4 accept related established rules':
      proto  => 'all',
      state  => ['RELATED', 'ESTABLISHED'],
      action => 'accept';
    '000 v6 accept related established rules':
      proto    => 'all',
      state    => ['RELATED', 'ESTABLISHED'],
      action   => 'accept',
      provider => 'ip6tables';
  }
  -> firewall {
    '010 v4 accept all to lo interface':
      proto   => 'all',
      iniface => 'lo',
      action  => 'accept';
    '010 v6 accept all to lo interface':
      proto    => 'all',
      iniface  => 'lo',
      action   => 'accept',
      provider => 'ip6tables';
  }
  -> firewall {
    '020 v4 accept icmp, heavy rate limited':
      proto  => 'icmp',
      limit  => '5/sec',
      burst  => 20,
      action => 'accept';
    '020 v4 reject with icmp udp echo, heavy rate limited':
      proto  => 'udp',
      limit  => '5/sec',
      burst  => 20,
      dport  => '33434-33523',
      reject => 'icmp-port-unreachable',
      action => 'reject';
    '029 v4 drop otherwise':
      proto  => 'icmp',
      action => 'drop';
    '020 v6 accept icmp, heavy rate limited':
      proto    => 'ipv6-icmp',
      limit    => '5/sec',
      burst    => 20,
      action   => 'accept',
      provider => 'ip6tables';
    '020 v6 reject with icmp udp echo, heavy rate limited':
      proto    => 'udp',
      limit    => '5/sec',
      burst    => 20,
      dport    => '33434-33523',
      reject   => 'icmp6-port-unreachable',
      action   => 'reject',
      provider => 'ip6tables';
    '029 v6 drop otherwise':
      proto    => 'ipv6-icmp',
      action   => 'drop',
      provider => 'ip6tables';
  }

  # OUTPUT and POSTROUTING are not purged to allow routers to do processing
  firewallchain {
    'INPUT:filter:IPv4':
      policy => 'drop',
      purge  => true;
    'FORWARD:filter:IPv4':
      policy => $forward_policy,
      purge  => true;
    'OUTPUT:filter:IPv4':
      policy => 'accept',
      purge  => false;
    'POSTROUTING:nat:IPv4':
      purge     => false;
    'INPUT:filter:IPv6':
      policy => 'drop',
      purge  => true;
    'FORWARD:filter:IPv6':
      policy => $forward_policy,
      purge  => true;
    'OUTPUT:filter:IPv6':
      policy => 'accept',
      purge  => false;
  }
}
