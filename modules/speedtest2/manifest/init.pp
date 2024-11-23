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

  ensure_packages(['ssl-cert', 'nginx'])

  file { '/etc/ssl/certs/server-fullchain.crt':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0644',
    source => 'puppet:///letsencrypt/fullchain.pem',
    links  => 'follow',
    notify => Service['nginx'],
  }

  file { '/etc/ssl/private/server.key':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0640',
    source => 'puppet:///letsencrypt/privkey.pem',
    links  => 'follow',
    notify => Service['nginx'],
  }

  service { 'nginx':
    ensure  => 'running',
    name    => 'nginx',
    enable  => true,
    require => Package['nginx'],
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure  =>absent,
    force   =>true,
    notify  =>Service['nginx'],
    require =>Package['nginx'],
  }

  file { 'speedtest2-conf':
    ensure  => file,
    path    => '/etc/nginx/sites-enabled/speedtest',
    content => template('speedtest2/speedtest.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

}
