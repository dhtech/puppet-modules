# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# Initial iptables rules that always applies

class iptables::ng::header {

  iptables::ng::advanced_rule { 'accept related established rules':
    type  => 'both',
    order => 1,
    rule  => [
      '-A INPUT -m state --state RELATED,ESTABLISHED',
      '-m comment --comment "accept related established rules"',
      '-j ACCEPT',
    ].join(' '),
  }

  iptables::ng::advanced_rule { 'accept all to lo interface':
    type  => 'both',
    order => 10,
    rule  => [
      '-A INPUT -i lo',
      '-m comment --comment "accept all to lo interface"',
      '-j ACCEPT',
    ].join(' '),
  }


  # IPv4 ICMP
  iptables::ng::advanced_rule { 'v4 accept icmp, heavy rate limited':
    type  => 'ipv4',
    order => 20,
    rule  => [
      '-A INPUT -p icmp',
      '-m limit --limit 5/sec --limit-burst 20',
      '-m comment --comment "accept icmp, heavy rate limited"',
      '-j ACCEPT',
    ].join(' '),
  }

  iptables::ng::advanced_rule { 'v4 reject with icmp udp echo, heavy rate limited':
    type  => 'ipv4',
    order => 21,
    rule  => [
      '-A INPUT -p udp',
      '-m multiport --dports 33434:33523',
      '-m limit --limit 5/sec --limit-burst 20',
      '-m comment --comment "reject with icmp udp echo, heavy rate limited"',
      '-j REJECT --reject-with icmp-port-unreachable',
    ].join(' '),
  }

  iptables::ng::advanced_rule { 'v4 drop remaining icmp':
    type  => 'ipv4',
    order => 29,
    rule  => [
      '-A INPUT -p icmp',
      '-m comment --comment "drop remaining icmp"',
      '-j DROP',
    ].join(' '),
  }


  # IPv6 ICMP
  iptables::ng::advanced_rule { 'v6 accept icmp, heavy rate limited':
    type  => 'ipv6',
    order => 20,
    rule  => [
      '-A INPUT -p ipv6-icmp',
      '-m limit --limit 5/sec --limit-burst 20',
      '-m comment --comment "accept icmp, heavy rate limited"',
      '-j ACCEPT',
    ].join(' '),
  }

  iptables::ng::advanced_rule { 'v6 reject with icmp udp echo, heavy rate limited':
    type  => 'ipv6',
    order => 21,
    rule  => [
      '-A INPUT -p udp',
      '-m multiport --dports 33434:33523',
      '-m limit --limit 5/sec --limit-burst 20',
      '-m comment --comment "reject with icmp udp echo, heavy rate limited"',
      '-j REJECT --reject-with icmp6-port-unreachable',
    ].join(' '),
  }

  iptables::ng::advanced_rule { 'v6 drop remaining icmp':
    type  => 'ipv6',
    order => 29,
    rule  => [
      '-A INPUT -p ipv6-icmp',
      '-m comment --comment "drop remaining icmp"',
      '-j DROP',
    ].join(' '),
  }

}
