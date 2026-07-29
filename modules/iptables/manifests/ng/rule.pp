# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: iptables::ng::rule
#
# Firewall rules for the firewall lib.
#
# === Parameters
#
# [*type*]
#   Version of the IP protocol for this rule. Must be one of `ipv4`,
#   `ipv6` or `both`
#
# [*chain*]
#   The chaing to place the rule in, defaults to `INPUT`
#
# [*action*]
#   What to do with traffic matching the rule. Used as `-j` parameter
#   for iptables, defaults to `ACCEPT`
#
# [*source*]
#   Source of the traffic, used as `-s` parameter for iptables
#
# [*proto*]
#   Protocol of the traffic, used as `-p` parameter for iptables
#
# [*dport*]
#   Destination port of the traffic, used as `--dports` parameter
#
# [*sport*]
#   Source port of the traffic, used as `--sports` parameter
#
# [*order*]
#   Allows you to change the order in which the rules are placed. Defaults
#   to `500`

define iptables::ng::rule (

  Enum['ipv4', 'ipv6', 'both'] $type,
  String $chain = 'INPUT',
  Enum['ACCEPT', 'REJECT', ''] $action = 'ACCEPT',
  Variant[String, Undef] $source = undef,
  Variant[String, Undef]  $proto = undef,
  Variant[String, Integer, Tuple, Undef] $dport = undef,
  Variant[String, Integer, Tuple, Undef] $sport = undef,
  Integer $order = 500,

) {

  include iptables::ng


  if $source {
    $source_line = "-s ${source}"
  }

  if $proto {
    $proto_line = "-p ${proto}"
  }

  if $dport or $sport {
    $multiport_line = '-m multiport'
  }

  $dport_line = $dport ? {
    String  => "--dports ${dport}",
    Integer => "--dports ${dport}",
    Array   => "--dports ${dport.join(',')}",
    Tuple   => "--dports ${dport.join(',')}",
    default => undef,
  }

  $sport_line = $sport ? {
    String  => "--sports ${sport}",
    Integer => "--sports ${sport}",
    Array   => "--sports ${sport.join(',')}",
    Tuple   => "--sports ${sport.join(',')}",
    default => undef,
  }

  $rule = [
    "-A ${chain}",
    $source_line,
    $proto_line,
    $multiport_line,
    $dport_line,
    $sport_line,
    '-m comment',
    "--comment \"${name}\"",
    "-j ${action}",
  ].filter |$e| { $e =~ NotUndef }.join(' ')


  if $type in ['ipv4', 'both'] {

    concat::fragment { $name:
        target  => $::iptables::ng::ipv4file,
        order   => $order,
        content => $rule,
    }

  }

  if $type in ['ipv6', 'both'] {

    concat::fragment { $name:
        target  => $::iptables::ng::ipv6file,
        order   => $order,
        content => $rule,
    }

  }

}
