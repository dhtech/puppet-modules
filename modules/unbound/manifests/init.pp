# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: unbound
#
# This class manages the unbound DNS resolver
#
# === Parameters
#
# Document parameters here.
#
# [*local*]
#
#  unbound will only listen on localhost, usable for machines doing lots of
#  lookups
#
# [*private_zones*]
#
# A list of private zones that should be queried at our resolvers.
#

class unbound ($local = 0, $private_zones = [], $stub_hosts = []) {

  # Only support local mode for now
  if $local == 1 {

    package { 'unbound':
      ensure => 'installed'
    }

    file { 'unbound.conf':
      path    => "/etc/unbound/unbound.conf",
      owner   => "root",
      group   => "root",
      mode    => "640",
      ensure  => file,
      content => template('unbound/unbound.conf.erb'),
      require => Package["unbound"],
    }
  }
}
