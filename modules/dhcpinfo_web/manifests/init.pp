# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: dhcpinfo_web
#
# This package manages the web frontend of dhcp_info
#
# === Parameters
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#

class dhcpinfo_web {

  package { 'apache2':
    ensure => 'installed',
  }

  service { 'apache2':
    ensure  => 'running',
    enable  => true,
    require => [
      Package['apache2'],
      File['/etc/ssl/certs/dhcpinfo.event.dreamhack.se.crt'],
      File['/etc/ssl/private/dhcpinfo.event.dreamhack.se.key']
    ],
  }

  file { '/etc/apache2/sites-available/dhcpinfo.event.dreamhack.se.conf':
    ensure  => 'file',
    path    => '/etc/apache2/sites-available/dhcpinfo.event.dreamhack.se.conf',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    source  => 'puppet:///scripts/dhcpinfo/apache_proxy/dhcpinfo.event.dreamhack.se',
    require => Package['apache2'],
    notify  => Service['apache2'],
  }

  package { 'thin':
    ensure => 'installed',
  }

  file { '/opt/dhcpinfo/thin':
    ensure => 'directory',
    path   => '/opt/dhcpinfo/thin',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/opt/dhcpinfo/public/bootstrap':
    recurse => true,
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///scripts/dhcpinfo/public/bootstrap',
  }

  file { '/opt/dhcpinfo/public/jquery.min.js':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///scripts/dhcpinfo/public/jquery.min.js',
  }

  file { '/opt/dhcpinfo/public/jquery.tablesorter.min.js':
    ensure => 'file',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///scripts/dhcpinfo/public/jquery.tablesorter.min.js',
  }

  file { '/opt/dhcpinfo/views':
    recurse => true,
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///scripts/dhcpinfo/views',
  }

  file { '/opt/dhcpinfo/lib':
    ensure => 'directory',
    path   => '/opt/dhcpinfo/lib',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { '/opt/dhcpinfo/thin/production_config.yml':
    ensure  => 'file',
    path    => '/opt/dhcpinfo/thin/production_config.yml',
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('dhcpinfo_web/production_config.yml.erb'),
    require => File['/opt/dhcpinfo/thin'],
  }

  file { '/opt/dhcpinfo/config.ru':
    ensure => 'file',
    path   => '/opt/dhcpinfo/config.ru',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///scripts/dhcpinfo/config.ru',
    notify => Supervisor::Restart['dhcpinfo_web_thin'],
  }

  package { ['ruby-sinatra', 'ruby-netaddr']:
    ensure => 'installed',
  }

  file { '/opt/dhcpinfo/app.rb':
    ensure => 'file',
    path   => '/opt/dhcpinfo/app.rb',
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///scripts/dhcpinfo/app.rb',
  }

  file { '/opt/dhcpinfo/lib/GetActiveLease.rb':
    ensure  => 'file',
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    path    => '/opt/dhcpinfo/lib/GetActiveLease.rb',
    source  => 'puppet:///scripts/dhcpinfo/lib/GetActiveLease.rb',
    require => File['/opt/dhcpinfo/lib'],
  }

  supervisor::register { 'dhcpinfo_web_thin':
    command   => 'thin -C thin/production_config.yml -R config.ru start',
    directory => '/opt/dhcpinfo',
    require   => [
          File['/opt/dhcpinfo/thin'],
          File['/opt/dhcpinfo/thin/production_config.yml'],
          File['/opt/dhcpinfo/config.ru'],
          Package['thin'],
          Package['ruby-sinatra'],
          Package['ruby-netaddr'],
    ]
  }

  exec { 'a2enmod_ssl':
      command => '/usr/sbin/a2enmod ssl',
      creates => '/etc/apache2/mods-enabled/ssl.load',
      require => Package['apache2'],
      notify  => Service['apache2'],
  }

  exec { 'a2enmod_rewrite':
      command => '/usr/sbin/a2enmod rewrite',
      creates => '/etc/apache2/mods-enabled/rewrite.load',
      require => Package['apache2'],
      notify  => Service['apache2'],
  }

  exec { 'a2enmod_proxy_http':
      command => '/usr/sbin/a2enmod proxy_http',
      creates => '/etc/apache2/mods-enabled/proxy_http.load',
      require => Package['apache2'],
      notify  => Service['apache2'],
  }

  exec { 'a2ensite_dhcpinfo':
      command => '/usr/sbin/a2ensite dhcpinfo.event.dreamhack.se',
      creates => '/etc/apache2/sites-enabled/dhcpinfo.event.dreamhack.se.conf',
      require => [
          File['/etc/apache2/sites-available/dhcpinfo.event.dreamhack.se.conf'],
          Exec['a2enmod_ssl'],
          Exec['a2enmod_rewrite'],
          Exec['a2enmod_proxy_http'],
      ],
      notify  => Service['apache2'],
  }

  exec {'mkdir':
    command => '/bin/mkdir -p /etc/apache2/site.d',
    creates => '/etc/apache2/site.d',
  }

  # Needed for 'ssl-cert' group
  ensure_packages(['ssl-cert'])

  file { '/etc/ssl/certs/dhcpinfo.event.dreamhack.se.crt':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0644',
    source => 'puppet:///letsencrypt/fullchain.pem',
    links  => 'follow',
  }

  file { '/etc/ssl/private/dhcpinfo.event.dreamhack.se.key':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0640',
    source => 'puppet:///letsencrypt/privkey.pem',
    links  => 'follow',
  }
}
