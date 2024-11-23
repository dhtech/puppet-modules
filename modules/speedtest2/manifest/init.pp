# Copyright 2024 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: speedtest 
#
# This class manages the speedtest
#
#
# === Parameters
#

class speedtest2 {

  $nginx_dir = '/etc/nginx'
  $sites_dir = "${nginx_dir}/sites-enabled"
  $rc_name = 'nginx'
  $www_root = '/var/www/html'

  package { 'nginx':
    ensure => installed,
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure  =>absent,
    force   =>true,
    notify  =>Service['nginx'],
    require =>Package['nginx'],
  }

  file { 'speedtest2-conf':
    ensure  => file,
    path    => "${sites_dir}/speedtest",
    content => template('speedtest2/speedtest.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  service { 'nginx':
    ensure  => 'running',
    name    => $rc_name,
    enable  => true,
    require => Package['nginx'],
  }
}
