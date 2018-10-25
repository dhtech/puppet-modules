# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: ci
#
# TODO(bluecmd): Currently this module *only* does firewall.
#
# === Parameters
#

class ci {
  firewall {
    '100 v4 masquerade outgoing inside traffic':
      table    => 'nat',
      chain    => 'POSTROUTING',
      proto    => 'all',
      outiface => 'eth0',
      jump     => 'MASQUERADE';
    '100 v6 masquerade outgoing inside traffic':
      table    => 'nat',
      chain    => 'POSTROUTING',
      proto    => 'all',
      outiface => 'eth0',
      jump     => 'MASQUERADE',
      provider => 'ip6tables';
    '110 v4 forward related established traffic':
      chain  => 'FORWARD',
      proto  => 'all',
      state  => ['RELATED', 'ESTABLISHED'],
      action => 'accept';
    '115 v4 drop outside traffic':
      chain   => 'FORWARD',
      proto   => 'all',
      iniface => 'eth0',
      action  => 'drop';
    '120 v4 forward traffic':
      chain  => 'FORWARD',
      proto  => 'all',
      action => 'accept';
    '110 v6 forward related established traffic':
      chain    => 'FORWARD',
      proto    => 'all',
      state    => ['RELATED', 'ESTABLISHED'],
      action   => 'accept',
      provider => 'ip6tables';
    '115 v6 drop outside traffic':
      chain    => 'FORWARD',
      proto    => 'all',
      iniface  => 'eth0',
      action   => 'drop',
      provider => 'ip6tables';
    '120 v6 forward traffic':
      chain    => 'FORWARD',
      proto    => 'all',
      action   => 'accept',
      provider => 'ip6tables';
  }
}
