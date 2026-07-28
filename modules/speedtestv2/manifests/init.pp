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

  # The ssl-cert package owns the ssl-cert group, so it has to be installed
  # before these are applied. Certificates are issued on the puppetmaster and
  # only copied down here, so nginx has to be reloaded when a renewed one
  # arrives - otherwise the old cert is served until someone restarts it.
  file { "/etc/ssl/certs/${::fqdn}.crt":
    ensure  => file,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0644',
    source  => 'puppet:///letsencrypt/fullchain.pem',
    links   => 'follow',
    require => Package['ssl-cert'],
    notify  => Service['nginx'],
  }

  file { "/etc/ssl/private/${::fqdn}.key":
    ensure  => file,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0640',
    source  => 'puppet:///letsencrypt/privkey.pem',
    links   => 'follow',
    require => Package['ssl-cert'],
    notify  => Service['nginx'],
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
    content => template('speedtestv2/speedtest.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  # purge drops the files nginx ships in its default web root, and clears out
  # assets left behind when the bundled OpenSpeedTest copy is upgraded.
  # 0644 keeps the static assets non-executable; Puppet adds the execute bit
  # back for directories on its own, so they end up 0755.
  file { '/usr/share/nginx/html':
    ensure  => directory,
    recurse => true,
    purge   => true,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/speedtestv2/Speed-Test-main/',
    require => Package['nginx'], #Make sure that apt install has been run
  }
}
