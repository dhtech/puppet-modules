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
#   Version of the IP protocol for this rule. Must be `4` or `6`.
#
# [*rule*]
#   The rule that should be used. In a format that can be understood
#   by `iptables-restore` it will have `-A ${chain} ` prepended
#
# [*order*]
#   Allows you to change the order in which the rules are placed. Header rules
#   should have `order < 200`, trailer rules `order >= 800`. Defaults to `500`

define iptables::ng::advanced_rule (

  Enum['ipv4', 'ipv6', 'both'] $type,
  String $rule,
  Integer $order = 500,

) {

  include iptables::ng


  if $type in ['ipv4', 'both'] {

    concat::fragment { "v4 ${name}":
        target  => $::iptables::ng::ipv4file,
        order   => $order,
        content => $rule,
    }

  }

  if $type in ['ipv6', 'both'] {

    concat::fragment { "v6 ${name}":
        target  => $::iptables::ng::ipv6file,
        order   => $order,
        content => $rule,
    }

  }

}
