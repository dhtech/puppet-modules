# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: openntpd
#
# This module manages ntpd on OpenBSD.
#
# === Parameters
#
# [*servers*]
#   The servers that will be used for time synchronisation
#
# [*server*]
#   Controls if the host will act as a NTP server

class openntpd ($servers = [], $server = 0) {

  file { 'ntpd.conf':
    path    => '/etc/ntpd.conf',
    ensure  => file,
    content => template('openntpd/ntpd.conf.erb'),
    notify  => Service["ntpd"],
  }

  service { 'ntpd':
    name => 'ntpd',
    ensure => 'running',
    enable => true,
  }
}
