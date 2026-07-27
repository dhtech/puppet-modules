# Copyright 2026 dhtech
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

class speedtestv2 {

  include apt

  package { 'nginx':
    ensure => installed,
  }

  package { 'ssl-cert':
    ensure => installed,
  }

    service { 'nginx':
    ensure  => running,
    enable  => true,
    require => Package['nginx'],
  }

  file { '/etc/ssl/certs/speedtest2.event.dreamhack.se.crt':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0644',
    source => 'puppet:///letsencrypt/fullchain.pem',
    links  => 'follow',
  }

  file { '/etc/ssl/private/speedtest2.event.dreamhack.se.key':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0640',
    source => 'puppet:///letsencrypt/privkey.pem',
    links  => 'follow',
  }

  file { '/etc/nginx/sites-enabled/default':
    ensure  => absent,
    force   => true,
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  file { 'speedtestv2-conf':
    ensure  => file,
    path    => '/etc/nginx/sites-enabled/speedtest',
    source  => 'puppet:///modules/speedtestv2/speedtest.conf',
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  file { '/usr/share/nginx/html/':
    ensure  => directory,
    recurse => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => 'puppet:///modules/speedtestv2/Speed-Test-main/',
    require => Package['nginx'], #Make sure that apt install has been run
  }
}
