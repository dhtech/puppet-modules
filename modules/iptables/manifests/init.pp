# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: iptables
#
# Firewall hooks for the firewall lib.
#
# === Parameters
#
# [*rules*]
#   The host specific rules for this machine as calculated from ipplan.
#
# [*log_fallthrough*]
#   Log the packets that will be policy dropped in the INPUT chain.
#
# [*forward_policy*]
#   What to do with packet forwards by default (drop (default)/accept)

class iptables ($rules, $log_fallthrough, $forward_policy = 'drop') {
  include stdlib::stages

  resources { 'firewall': purge => false }

  Firewall {
    before  => Class['iptables::post'],
    require => Class['iptables::pre'],
  }

  # The 'stages' below are needed because we need to add 'pre' before we purge
  # the rest. Without these stages a newly installed machine will deadlock in
  # that it will purge the existing rules, start to block everything, and wait
  # for APT to download new packages. This fixes this by temporarily adding
  # the new set (iptables::pre) at the end of the ones we ship in a basic
  # installation. This will make the rules look a bit weird and redundant
  # just when the first run is being made - but it will work and after the run
  # everything will be just right.
  class {
    'firewall':
      stage => 'setup';
    'iptables::pre':
      stage => 'setup',
      forward_policy => $forward_policy;
    'iptables::post':
      stage => 'deploy',
      log => $log_fallthrough;
  }

  each($rules['v4']) |$rule| {
    $name = $rule['name']
    $proto = $rule['proto']
    firewall {
      "500 v4 $name $proto":
        source    => $rule['src'],
        proto     => $rule['proto'],
        dport     => $rule['dports'],
        sport     => $rule['sports'],
        action    => 'accept';
    }
  }

  each($rules['v6']) |$rule| {
    $name = $rule['name']
    $proto = $rule['proto']
    firewall {
      "500 v6 $name $proto":
        source    => $rule['src'],
        proto     => $rule['proto'],
        dport     => $rule['dports'],
        sport     => $rule['sports'],
        action    => 'accept',
        provider  => 'ip6tables';
    }
  }
}
