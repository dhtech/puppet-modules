# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: supervisor
#
# This class manages the supervisor system.
# See http://supervisord.org/
#
# === Parameters
#

class supervisor {

  if $::operatingsystem == 'OpenBSD' {
    $conf_dir = '/etc'
    $rc_name = 'supervisord'
  }
  else {
    $conf_dir = '/etc/supervisor'
    $rc_name = 'supervisor'
  }

  package { 'supervisor':
    ensure => installed,
  }

  file { 'supervisord.conf':
    ensure  => file,
    path    => "${conf_dir}/supervisord.conf",
    content => template('supervisor/supervisord.conf.erb'),
    notify  => Service['supervisord'],
    require => Package['supervisor'],
  }

  service { 'supervisord':
    ensure  => 'running',
    name    => $rc_name,
    enable  => true,
    require => Package['supervisor'],
  }

}
