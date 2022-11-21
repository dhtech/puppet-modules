# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: bind
#
# This class manages the bind DNS server.
#
# === Parameters
#
# [*role*]
#   Decides what role the server will have (authorative or resolver)
#
# [*networks*]
#   A list of networks the server will allow recursive lookups from when acting
#   as a resolver, by default localhost.
#
# [*zones*]
#   Zones that will be authoritatively served by the server.
#
# [*private_zones*]
#   Zones that will be authoritatively served by the server with restrictive ACLs.
#
# [*also_notify*]
#   Machines that are not in NS records but should be notified of zone changes.
#
# [*rfc_1918_resolvers*]
#   Machines that are allowed to query for reverse records in RFC1918 networks.

class bind($role='resolver', $networks = [], $zones = [], $private_zones = [],
            $allow_transfer = [], $also_notify = [], $rfc_1918_resolvers = []) {

  if $::operatingsystem == 'OpenBSD' {
    $named_user = '_bind'
    $conf_dir = '/var/named/etc'
    $conf_cfg = 'etc'
    $package_name = 'isc-bind'
    $rc_name = 'isc_named'
    $needs_tools = 0
    $needs_slave_dir = 0
    $standard_zone_dir = '/var/named/standard'
    $standard_zone_cfg = 'standard'
    $slave_zone_dir = '/var/named/slave'
    $slave_zone_cfg = 'slave'
    $master_zone_dir = '/var/named/master'
    $master_zone_cfg = 'master'
    $dump_dir = '/var/named/tmp/dump'
    $dump_dir_cfg = 'tmp/dump'
    $stats_dir = '/var/named/tmp/stats'
    $stats_dir_cfg = 'tmp/stats'
  }
  else {
    $named_user = 'bind'
    $conf_dir = '/etc/bind'
    $conf_cfg = '/etc/bind'
    $package_name = 'bind9'
    $rc_name = 'bind9'
    $needs_tools = 1
    $needs_slave_dir = 1
    $standard_zone_dir = '/etc/bind'
    $standard_zone_cfg = '/etc/bind'
    $slave_zone_dir = '/etc/bind/slave'scripts
    $slave_zone_cfg = '/etc/bind/slave'
    $master_zone_dir = '/etc/bind/master'
    $master_zone_cfg = '/etc/bind/master'
    $dump_dir = '/var/cache/bind/dump'
    $dump_dir_cfg = '/var/cache/bind/dump'
    $stats_dir = '/var/cache/bind/stats'
    $stats_dir_cfg = '/var/cache/bind/stats'
  }

  package { $package_name:
    ensure => installed,
  }

  package { 'dnstop':
    ensure => installed,
  }

  package { 'dns-root-data':
    ensure => installed,
  }

  # It is nice to have dig(1) on a DNS server
  if $needs_tools == 1 {
    package { 'dnsutils':
      ensure => installed,
    }
  }

  # Make sure the slave directory exists
  if $needs_slave_dir == 1 {
    file { 'slavedir':
      ensure  => 'directory',
      owner   => 'root',
      group   => $named_user,
      mode    => '0770',
      path    => $slave_zone_dir,
      require => Package[$package_name],
    }
  }

  # We need a managed-keys directory on OpenBSD where BIND has write
  # permissions for use with "dnssec-validation auto;"
  if $::operatingsystem == 'OpenBSD' {
    file { 'managed-keys-dir':
      ensure  => 'directory',
      owner   => 'root',
      group   => $named_user,
      mode    => '0770',
      path    => '/var/named/managed-keys',
      require => Package[$package_name],
    }
  }

  # Make sure the dump directory exists
  file { 'dumpdir':
    ensure  => 'directory',
    owner   => 'root',
    group   => $named_user,
    mode    => '0770',
    path    => $dump_dir,
    require => Package[$package_name],
  }

  # Make sure the stats directory exists
  file { 'statsdir':
    ensure  => 'directory',
    owner   => 'root',
    group   => $named_user,
    mode    => '0770',
    path    => $stats_dir,
    require => Package[$package_name],
  }

  file { 'named.conf':
    ensure  => file,
    path    => "${conf_dir}/named.conf",
    content => template('bind/named.conf.erb'),
    notify  => Service['named'],
    require => Package[$package_name],
  }

  file { 'bind_exporter_binary':
    ensure => file,
    path   => '/usr/sbin/bind_exporter',
    mode   => '0755',
    source => 'puppet:///data/bind_exporter',
    links  => follow,
    notify => [ Service['bind_exporter'] ],
  }

  file { 'bind_exporter.service':
    ensure  => file,
    path    => '/etc/systemd/system/bind_exporter.service',
    content => template('bind/exporter.erb'),
  }
  ~> exec { '/bin/systemctl daemon-reload':
    refreshonly => true,
    notify      => [ Service['bind_exporter'] ],
  }

  service { 'bind_exporter':
    ensure  => 'running',
    enable  => true,
    require => File['bind_exporter_binary'],
  }

  file { 'named.conf.slave':
    ensure  => file,
    path    => "${conf_dir}/named.conf.slave",
    content => template('bind/named.conf.slave.erb'),
    notify  => Service['named'],
    require => Package[$package_name],
  }

  if $role == 'resolver' {

    file { 'db.0':
      ensure  => file,
      path    => "${standard_zone_dir}/db.0",
      content => template('bind/db.0.erb'),
      notify  => Service['named'],
      require => Package[$package_name],
    }

    file { 'db.127':
      ensure  => file,
      path    => "${standard_zone_dir}/db.127",
      content => template('bind/db.127.erb'),
      notify  => Service['named'],
      require => Package[$package_name],
    }

    file { 'db.255':
      ensure  => file,
      path    => "${standard_zone_dir}/db.255",
      content => template('bind/db.255.erb'),
      notify  => Service['named'],
      require => Package[$package_name],
    }

    file { 'db.local':
      ensure  => file,
      path    => "${standard_zone_dir}/db.local",
      content => template('bind/db.local.erb'),
      notify  => Service['named'],
      require => Package[$package_name],
    }

    file { 'db.loopback6.arpa':
      ensure  => file,
      path    => "${standard_zone_dir}/db.loopback6.arpa",
      content => template('bind/db.loopback6.arpa.erb'),
      notify  => Service['named'],
      require => Package[$package_name],
    }
  }

  service { 'named':
    ensure  => 'running',
    name    => $rc_name,
    enable  => true,
    require => Package[$package_name],
  }

  if $::lsbdistcodename != 'buster' {
    file { '/etc/apparmor.d/local/usr.sbin.named':
    ensure => 'file',
    notify => Service['apparmor'],
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/bind/local.usr.sbin.named',
  }

  service { 'apparmor':
    ensure => 'running',
    enable => true,
    }
  }
}
