# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: pf
#
# Firewall hooks for the firewall lib.
#
# === Parameters
#
# [*rules*]
#   The host specific rules for this machine as calculated from ipplan.
#
# [*forward_policy*]
#   What to do with packet forwards by default (drop/accept)

class pf ($rules, $forward_policy) {

  $pf_conf_path = '/etc/pf.conf'

  file { 'pf.conf':
    path    => $pf_conf_path,
    ensure  => file,
    content => template('pf/pf.conf.erb'),
  }

  exec { "/sbin/pfctl -f $pf_conf_path":
    subscribe   => File["pf.conf"],
    refreshonly => true
  }
}
