# Copyright 2026 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: speedtestv2
#
# This class manages the speedtestv2 site
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
  #
  # The download payload is generated below rather than shipped, so it has to
  # be ignored here: purge would otherwise delete it on every run, and it
  # would be recreated on the next one.
  file { '/usr/share/nginx/html':
    ensure  => directory,
    recurse => true,
    purge   => true,
    ignore  => ['downloading'],
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///modules/speedtestv2/Speed-Test-main/',
    require => Package['nginx'], #Make sure that apt install has been run
  }

  # The client downloads this repeatedly to measure throughput, so it only has
  # to be incompressible and large enough not to finish instantly. Generating
  # it on the node keeps 30MiB of random bytes out of the repository, where it
  # would sit in history forever and be cloned by everyone.
  exec { 'speedtestv2-download-payload':
    command => 'head -c 30M /dev/urandom > /usr/share/nginx/html/downloading',
    creates => '/usr/share/nginx/html/downloading',
    path    => ['/usr/bin', '/bin'],
    require => File['/usr/share/nginx/html'],
  }

  file { '/usr/share/nginx/html/downloading':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Exec['speedtestv2-download-payload'],
  }
}
