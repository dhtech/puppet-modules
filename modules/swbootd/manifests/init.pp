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

  $secret_radius_access   = vault('radius:access', {})
  $secret_snmpv2_access   = vault('snmpv2:access', {})
  $secret_snmpsalt_access = vault('snmpsalt:access', {})
  $secret_enable_access   = vault('enable:access', {})
  $secret_login_access    = vault('login:access', {})
  $secret_login_svn       = vault('login:svn', {})

  ensure_packages([
    'isc-dhcp-server',
    'redis-server',
    'python3-redis',
    'python3-tempita',
    'python3-yaml',
    'python3-pip',
    'python3-setuptools',
    'libsnmp-dev',
    'build-essential',
    'python3-dev',
    'python3-six',
    'python3-wheel',
    'snmp'])

  package { 'python3-netsnmp':
    provider => pip3,
  }
  package { 'ipcalc':
    provider => pip3,
  }
  package { 'passlib':
    provider => pip3,
  }

  # The default configuration file
  file { 'default-isc-dhcp-server':
    ensure  => file,
    path    => '/etc/default/isc-dhcp-server',
    content => template('swbootd/default-isc-dhcp-server.erb'),
    notify  => Service['isc-dhcp-server'],
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
    notify  => Supervisor::Restart['swtftpd','swhttpd'],
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

  supervisor::register{ 'swhttpd':
    command => '/scripts/swboot/swhttpd.py',
  }

  file { '/scripts/swboot/switchconfig':
    ensure  => directory,
    recurse => remote,
    source  => "puppet:///svn/${current_event}/access/switchconfig",
    notify  => Supervisor::Restart['swtftpd','swhttpd'],
  }

  file { '/srv/tftp':
    ensure  => directory,
  }
}
