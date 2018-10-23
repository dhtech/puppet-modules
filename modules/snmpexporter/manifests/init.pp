# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: snmpexporter
#
# dhmon snmpexporter
#
# [*layers*]
#   Array of layer config (dict of key, values)
#
# === Parameters

class snmpexporter($layers) {
  ensure_packages([
    'libsnmp-dev',
    'python3-distutils',
    'python3-dev',
    'python3-coverage',
    'python3-yaml',
    'python3-objgraph',
    'python3-twisted',
    'python3-pip',
    'python3-setuptools',
    'python3-wheel',
    'unzip',
    'build-essential',
    'nginx',
  ])

  package { 'python3-netsnmp':
    provider => 'pip3',
  }

  # Configure MIB lookup
  file { 'snmp.conf':
    path    => '/etc/snmp/snmp.conf',
    content => template('snmpexporter/snmp.conf.erb'),
    ensure  => present,
  }

  # Install DH MIBs
  file { 'other-mibs':
    path    => '/var/lib/mibs/other',
    ensure  => directory,
    recurse => remote,
    source  => 'puppet:///svn/allevents/mibs/'
  }

  # Install standard MIBs
  file { '/var/lib/mibs/std/':
    ensure  => 'directory',
  }

  file { '/opt/librenms.zip':
    ensure    => present,
    replace   => no,
    source    => 'https://github.com/librenms/librenms/archive/master.zip',
  }~>
  exec { 'unzip librenms':
    creates     => '/opt/librenms-master/mibs/',
    command     => '/usr/bin/unzip /opt/librenms.zip librenms-master/mibs/*',
    cwd         => '/opt',
  }~>
  exec { 'copy mibs':
    command     => '/bin/cp -r /opt/librenms-master/mibs/* /var/lib/mibs/std/',
    creates     => '/var/lib/mibs/std/TCP-MIB',
    require     => File['/var/lib/mibs/std/'],
  }

  user { 'prober-user':
    name           => 'prober',
    forcelocal     => yes,
    home           => '/tmp',
    password       => '*',
    purge_ssh_keys => true,
    shell          => '/usr/sbin/nologin',
  }

  file { '/etc/snmpexporter':
    ensure => 'directory',
  }

  file { 'auth.yaml':
    path    => '/etc/snmpexporter/auth.yaml',
    content => template('snmpexporter/auth.yaml.erb'),
    ensure  => present,
  }

  file { 'snmpexporter.yaml':
    path    => '/etc/snmpexporter/snmpexporter.yaml',
    source  => 'puppet:///scripts/snmpexporter/etc/snmpexporter.yaml',
    ensure  => present,
  }

  file { 'snmpexporterd.service':
    path    => '/etc/systemd/system/snmpexporterd@.service',
    content => template('snmpexporter/snmpexporterd@.service.erb'),
    ensure  => present,
  }

  # Since the python snmpexporter only scales so far, run multiple ones and
  # load balance across them.
  $ports = ['9190', '9191', '9192', '9193', '9194', '9195', '9196', '9197']
  $ports.each |String $port| {
    service { "snmpexporterd@${port}":
      ensure    => 'running',
      enable    => true,
      subscribe => [
        File['snmpexporterd.service'],
        Exec['make-snmpexporter']
      ],
      require   => [File['snmpexporterd.service']],
    }
  }

  file { 'nginx.conf':
    path    => '/etc/nginx/nginx.conf',
    content => template('snmpexporter/nginx.conf.erb'),
    ensure  => present,
    notify  => Service['nginx'],
  }

  service { 'nginx':
    ensure    => 'running',
    enable    => true,
    require   => [File['nginx.conf']],
  }

  file { '/opt/snmpexporter.src':
    ensure  => directory,
    recurse => remote,
    source  => 'puppet:///scripts/snmpexporter/',
  }~>
  exec { 'make-snmpexporter':
    command     => '/usr/bin/make all install',
    cwd         => '/opt/snmpexporter.src',
    refreshonly => true,
  }
}
