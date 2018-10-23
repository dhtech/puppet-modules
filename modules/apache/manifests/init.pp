# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: apache
#
# This class manages an Apache server.
#
# === Parameters
#
# [*ldap*]
#   If LDAP authentication is needed, specify the LDAP server. Default is to
#   not do LDAP authentication.
#

class apache($ldap = nil) {

  package { 'apache2':
    ensure => installed,
  }
  service { 'apache2':
    ensure => running,
  }
  exec { 'a2enmod_ssl':
    command => '/usr/sbin/a2enmod ssl',
    creates => '/etc/apache2/mods-enabled/ssl.load',
    require => Package['apache2'],
    notify  => Service['apache2'],
  }

  file { 'default-ssl.conf':
    path    => '/etc/apache2/sites-enabled/default-ssl.conf',
    ensure  => present,
    content => template('apache/default-ssl.conf.erb'),
    notify  => Service['apache2'],
    require => [
      File['/etc/ssl/certs/server-fullchain.crt'],
      File['/etc/ssl/private/server.key']
    ],
  }

  file { 'apache-ports.conf':
    path    => '/etc/apache2/ports.conf',
    ensure  => present,
    content => template('apache/ports.conf.erb'),
    notify  => Service['apache2'],
  }

  if $::fqdn == 'dhmon.event.dreamhack.se' {
    file { 'apache-security.conf':
        path    => '/etc/apache2/conf-available/security.conf',
        ensure  => present,
        notify  => Service['apache2'],
        content => template('apache/security-dhmon.conf.erb'),
    }
  } else {
    file { 'apache-security.conf':
        path    => '/etc/apache2/conf-available/security.conf',
        ensure  => present,
        notify  => Service['apache2'],
        content => template('apache/security.conf.erb'),
    }
  }

  file { 'site.d':
    path    => '/etc/apache2/site.d',
    ensure  => directory,
  }

  exec { 'a2enmod_proxy_http':
    command => '/usr/sbin/a2enmod proxy_http',
    creates => '/etc/apache2/mods-enabled/proxy_http.load',
    require => [
      File['default-ssl.conf'],
      Package['apache2'],
    ],
    notify  => Service['apache2'],
  }

  exec { 'a2enmod_authnz_ldap':
    command => '/usr/sbin/a2enmod authnz_ldap',
    creates => '/etc/apache2/mods-enabled/authnz_ldap.load',
    require => Package['apache2'],
    notify  => Service['apache2'],
  }

  exec { 'a2enmod_headers':
    command => '/usr/sbin/a2enmod headers',
    creates => '/etc/apache2/mods-enabled/headers.load',
    require => Package['apache2'],
    notify  => Service['apache2'],
  }

  file { '000-default.conf':
    path   => '/etc/apache2/sites-enabled/000-default.conf',
    ensure => absent,
    notify => Service['apache2'],
  }

  exec { 'a2ensite_ssl':
    command => '/usr/sbin/a2ensite default-ssl',
    creates => '/etc/apache2/sites-enabled/default-ssl.conf',
    require => [
      File['default-ssl.conf'],
      Exec['a2enmod_ssl'],
      Exec['a2enmod_proxy_http'],
    ],
    notify => Service['apache2'],
  }

  # Needed for 'ssl-cert' group
  ensure_packages(['ssl-cert'])

  file { '/etc/ssl/certs/server-fullchain.crt':
    ensure  => file,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0644',
    source  => 'puppet:///letsencrypt/fullchain.pem',
    links   => 'follow',
    notify  => Service['apache2'],
  }

  file { '/etc/ssl/private/server.key':
    ensure  => file,
    owner   => 'root',
    group   => 'ssl-cert',
    mode    => '0640',
    source  => 'puppet:///letsencrypt/privkey.pem',
    links   => 'follow',
    notify  => Service['apache2'],
  }

}
