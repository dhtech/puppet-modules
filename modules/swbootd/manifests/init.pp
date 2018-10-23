# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: swbootd
#
# swboot switch configuration daemon
#
# === Parameters
#
# [*current_event*]
#   Used for retrieving switchconfig for current event
#

class swbootd($current_event) {

  $secret_radius_access   = vault("radius:access", {})
  $secret_snmpv2_access   = vault("snmpv2:access", {})
  $secret_snmpsalt_access = vault("snmpsalt:access", {})
  $secret_enable_access   = vault("enable:access", {})
  $secret_login_access    = vault("login:access", {})
  $secret_login_svn       = vault("login:svn", {})

  ensure_packages([
    'isc-dhcp-server',
    'redis-server',
    'python-redis',
    'python-netsnmp',
    'python-tempita',
    'python-ipcalc',
    'python-yaml',
    'python-six',
    'snmp'])

  # The default configuration file
  file { 'default-isc-dhcp-server':
    path    => "/etc/default/isc-dhcp-server",
    ensure  => file,
    content => template("swbootd/default-isc-dhcp-server.erb"),
    notify  => Service["isc-dhcp-server"],
  }

  file { '/etc/dhcp/dhcpd.conf':
    ensure => link,
    target => '/scripts/swboot/dhcpd.conf',
    notify => Service['isc-dhcp-server'],
  }

  service { ['isc-dhcp-server', 'redis-server']:
    ensure  => running,
  }

  file { '/scripts/swboot/config.py':
    ensure  => file,
    content => template('swbootd/config.py.erb'),
    mode    => '0700',
    notify  => Supervisor::Restart['swtftpd'],
  }

  file { '/etc/network/interfaces.d/swboot':
    ensure  => file,
    content => template('swbootd/interfaces.erb'),
    notify  => Exec['restart-ens224'],
  }

  exec { 'restart-ens224':
    command     => '/sbin/ifdown ens224; /sbin/ifup ens224',
    refreshonly => true,
  }

  supervisor::register{ 'swtftpd':
    command => '/scripts/swboot/swtftpd.py',
  }

  file { '/scripts/swboot/switchconfig':
    ensure => directory,
    recurse => remote,
    source => "puppet:///svn/${current_event}/access/switchconfig",
    notify  => Supervisor::Restart['swtftpd'],
  }
}
