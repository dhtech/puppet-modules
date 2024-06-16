# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: akvorado
#
# Alert manager for prometheus to handle sending alerts
#
# === Parameters
#

class akvorado {

  #Create user/group for Akvorodo
  group { 'akvorado':
    ensure => 'present',
  }
  -> user { 'akvorado':
    ensure => 'present',
    system => true,
  }
  #Create directories for akvorado
  -> file { '/etc/akvorado':
    ensure => 'directory',
    owner  => 'root',
    group  => 'akvorado',
    mode   => '0750',
  }
  #Copy akvorado to the server
  -> file { '/usr/local/bin/akvorado':
    ensure => file,
    owner  => 'root',
    group  => 'akvorado',
    mode   => '0550',
    links  => follow,
    source => 'puppet:///data/akvorado-latest',
  }
  
  file { '/etc/akvorado/akvorado.yaml':
    ensure  => file,
    content => template('akvorado/akvorado.yaml.erb'),
    notify  => Service['akvorado-orch'],
  }
  #Systemctl config
  file { '/etc/systemd/system/akvorado-orch.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/akvorado-orch.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [Exec['systemctl-daemon-reload'],Service['akvorado-orch']],
  }
  file { '/etc/systemd/system/akvorado-inlet.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/akvorado-inlet.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [Exec['systemctl-daemon-reload'],Service['akvorado-inlet']],
  }
  file { '/etc/systemd/system/akvorado-console.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/akvorado-console.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [Exec['systemctl-daemon-reload'],Service['akvorado-console']],
  }
  
  -> apache::proxy { 'akvorado':
    url     => '/',
    backend => 'http://localhost:8082/',
  }
  -> service { 'akvorado-orch':
    ensure  => running,
  }
-> service { 'akvorado-inlet':
    ensure  => running,
  }
-> service { 'akvorado-console':
    ensure  => running,
  }


  exec { 'systemctl-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }
}
