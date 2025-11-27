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

class speedtestv2 {

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

  file { 'speedtestv2-conf':
    ensure  => file,
    path    => '/etc/nginx/sites-enabled/speedtest',
    content => template('speedtestv2/speedtest.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  # Needed for 'ssl-cert' group
  ensure_packages(['ssl-cert'])

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

  -> file { 'speedtestv2-downloading':
    ensure => file,
    owner  => 'nginx',
    group  => 'nginx',
    mode   => '0644',
    source => 'puppet:///modules/speedtestv2/downloading',
  }

  file { 'speedtestv2-index':
    ensure  => file,
    path    => '/usr/share/nginx/html/index.html',
    content => template('speedtestv2/index.html.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  file { 'speedtestv2-hosted':
    ensure  => file,
    path    => '/usr/share/nginx/html/hosted.html',
    content => template('speedtestv2/hosted.html.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  file { 'speedtestv2-upload':
    ensure  => file,
    path    => '/usr/share/nginx/html/upload',
    content => template('speedtestv2/upload.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }
}
