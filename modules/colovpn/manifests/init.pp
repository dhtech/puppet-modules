# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: colovpn
#
# Special firewall rules for colovpn.
#
# === Parameters
#
# [*link_net4*]
#   Link network in use for site-to-site links (v4).
#
# [*link_net6*]
#   Link network in use for site-to-site links (v6).

class colovpn ($link_net4 = '172.29.16.0/24', $link_net6 = '2a05:2240:5000:a::/64') {

  firewall {
    "200 v4 allow bgp on site-to-site VPN":
      source => $link_net4,
      proto  => 'tcp',
      dport  => 179,
      action => 'accept';
    "200 v6 allow bgp on site-to-site VPN":
      source => $link_net6,
      proto  => 'tcp',
      dport  => 179,
      action => 'accept',
      provider  => 'ip6tables';
  }

}
