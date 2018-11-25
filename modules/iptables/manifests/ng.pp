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
# [*chains*]
#   A hash containing chains with their default policy. Defaults to
#   ```
#   {
#     'INPUT'   => 'DROP',
#     'FORWARD' => 'DROP',
#     'OUTPUT'  => 'ACCEPT',
#   }
#   ```
# [*ipv4file*]
#   The file to store the IPv4 rules in. Defaults to
#   `/etc/iptables/rules.v4.puppet`
#
# [*ipv6file*]
#   The file to store the IPv6 rules in. Defaults to
#   `/etc/iptables/rules.v6.puppet`

class iptables::ng (

  Hash $rules,
  Boolean $log_fallthrough,
  Hash[String, Enum['ACCEPT', 'DROP', 'REJECT'], 1] $chains = {
    'INPUT'   => 'DROP',
    'FORWARD' => 'DROP',
    'OUTPUT'  => 'ACCEPT',
  },
  String $ipv4file = '/etc/iptables/rules.v4.puppet',
  String $ipv6file = '/etc/iptables/rules.v6.puppet',

) {

  $chains_header = $chains.map |$chain,$policy| { sprintf(':%s %s [0:0]', $chain, $policy) }

  $enforce_command = '/usr/local/sbin/enforce-iptables'
  file { 'enforce-command':
    path   => $enforce_command,
    source => 'puppet:///scripts/iptables/enforce-iptables.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }


  # Header and trailer rules
  class { 'iptables::ng::header': }
  class { 'iptables::ng::trailer':
    log_input => $log_fallthrough,
  }


  # IPv4
  concat { $ipv4file:
    ensure         => present,
    backup         => true,
    warn           => '# This file is managed by Puppet. Do not edit.',
    order          => 'numeric',
    validate_cmd   => '/usr/sbin/iptables-restore -t < %',
    ensure_newline => true,
    notify         => Exec['enforce-puppet-iptables'],
  }

  concat::fragment { '00-ipv4-header':
    target  => $ipv4file,
    order   => 0,
    content => ([
      '*filter'
    ] + $chains_header).join("\n"),
  }

  concat::fragment { '99-ipv4-trailer':
    target  => $ipv4file,
    order   => 9999,
    content => [
      'COMMIT'
    ].join("\n"),
  }

  exec { 'enforce-puppet-iptables':
    command     => "/usr/bin/echo ${enforce_command} ipv4 '${ipv4file}'",
    refreshonly => true,
    require     => File['enforce-command'],
  }

  each($rules['v4']) |$rule| {
    $name = $rule['name']
    $proto = $rule['proto']

    iptables::ng::rule { "v4 ${name} ${proto}":
        type   => 'ipv4',
        chain  => 'INPUT',
        action => 'ACCEPT',
        order  => 500,
        source => $rule['src'],
        proto  => $rule['proto'],
        dport  => $rule['dports'],
        sport  => $rule['sports'],
    }
  }


  # IPv6
  concat { $ipv6file:
    ensure         => present,
    backup         => true,
    warn           => '# This file is managed by Puppet. Do not edit.',
    order          => numeric,
    validate_cmd   => '/usr/sbin/ip6tables-restore -t < %',
    ensure_newline => true,
    notify         => Exec['enforce-puppet-ip6tables'],
  }

  concat::fragment { '00-ipv6-header':
    target  => $ipv6file,
    order   => 0,
    content => ([
      '*filter'
    ] + $chains_header).join("\n"),
  }

  concat::fragment { '99-ipv6-trailer':
    target  => $ipv6file,
    order   => 9999,
    content => [
      'COMMIT',
    ].join("\n"),
  }

  exec { 'enforce-puppet-ip6tables':
    command     => "/usr/bin/echo ${enforce_command} ipv6 '${ipv6file}'",
    refreshonly => true,
    require     => File['enforce-command'],
  }

  each($rules['v6']) |$rule| {
    $name = $rule['name']
    $proto = $rule['proto']

    iptables::ng::rule { "v6 ${name} ${proto}":
        type   => 'ipv6',
        chain  => 'INPUT',
        action => 'ACCEPT',
        order  => 500,
        source => $rule['src'],
        proto  => $rule['proto'],
        dport  => $rule['dports'],
        sport  => $rule['sports'],
    }
  }

}
