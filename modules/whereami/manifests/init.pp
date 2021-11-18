# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: whereami 
#
# This module manages the whereami-app 
#
# === Parameters
#
# [*current_event*]
#   Used for setting the name of the whereami database.
#

class whereami($current_event) {

  $secret_dist_snmpv3    = vault('snmpv3:dist', {})
  $secret_access_snmpv2  = vault('snmpv2:access', {})
  $secret_db_dhcpinfo    = vault('postgresql:dhcpinfo', {})
  $secret_db_whereami    = vault('postgresql:whereami', {})

  ensure_packages([
    'gcc',
    'libsnmp-dev',
    'python3-dev',
    'libsnmp40',
    'python3-psycopg2',
    'python3-flask'])

  package { 'python3-netsnmp':
    provider => 'pip',
  }

  apache::proxy { 'whereami-backend':
    url     => '/',
    backend => 'http://localhost:80/',
    require => Supervisor::Register['whereami'],
  }

  file { '/opt/whereami':
    ensure => 'directory',
    mode   => '0750',
    owner  => 'root',
    group  => 'root',
  }

  file { '/opt/whereami/config':
    content => template('whereami/config.erb'),
    mode    => '0640',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/whereami'],
    notify  => Supervisor::Restart['whereami'],
  }

  file { '/etc/systemd/system/whereami.service':
    content => template('whereami/service.erb'),
    mode    => '0640',
    owner   => 'root',
    group   => 'root',
  }

  -> exec { 'whereami-systemd-reload':
    command     => 'systemctl daemon-reload',
    path        => [ '/usr/bin', '/bin', '/usr/sbin' ],
    refreshonly => true,
  }

  file { '/opt/whereami/static':
    ensure  => 'directory',
    source  => 'puppet:///scripts/whereami3/static/',
    recurse => true,
  }

  file { '/opt/whereami/whereami3.py':
    source  => 'puppet:///scripts/whereami3/whereami3.py',
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/whereami'],
  }

  file { '/opt/whereami/init_db.py':
    source  => 'puppet:///scripts/whereami3/init_db.py',
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/whereami'],
    notify  => Exec['whereami-dbinit'],
  }

  exec { 'whereami-dbinit':
    command     => '/opt/whereami/init_db.py',
    refreshonly => true,
    cwd         => '/opt/whereami',
  }

  file { '/opt/whereami/v6api.py':
    source  => 'puppet:///scripts/whereami3/v6api.py',
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/whereami'],
  }

  file { '/opt/whereami/check_ipv6_api.py':
    source  => 'puppet:///scripts/whereami3/check_ipv6_api.py',
    mode    => '0750',
    owner   => 'root',
    group   => 'root',
    require => File['/opt/whereami'],
  }

  file { '/opt/whereami/templates':
    recurse => true,
    owner   => 'root',
    group   => 'root',
    source  => 'puppet:///scripts/whereami3/templates',
    require => File['/opt/whereami'],
  }

  service { 'whereami':
    ensure   => running,
    enable   => true,
    provider => provider,
    require  => [
      File['/opt/whereami/templates'],
      File['/opt/whereami/check_ipv6_api.py'],
      File['/opt/whereami/init_db.py'],
      File['/opt/whereami/v6api.py'],
      File['/opt/whereami/whereami3.py'],
      File['/opt/whereami/check_ipv6_api.py'],
      File['/opt/whereami/config'],
      Package['python3-netsnmp'],
      Package['python3-psycopg2'],
      Package['python3-flask'],
      Package['gcc'],
      Package['python3-dev'],
      Package['libsnmp-dev'],
      Package['libsnmp40'],
    ],
  }
}
