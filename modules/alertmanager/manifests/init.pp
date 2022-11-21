# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: alertmanager
#
# Alert manager for prometheus to handle sending alerts
#
# === Parameters
#

class alertmanager {

  #Create user/group for Prometheus
  group { 'alertmanager':
    ensure => 'present',
  }
  -> user { 'alertmanager':
    ensure => 'present',
    system => true,
  }
  #Create directories for alertmanager
  -> file { '/opt/alertmanager':
    ensure => 'directory',
    owner  => 'alertmanager',
    group  => 'alertmanager',
    mode   => '0700',
  }
  -> file { '/srv/alertmanager':
    ensure => 'directory',
    owner  => 'alertmanager',
    group  => 'alertmanager',
    mode   => '0700',
  }

  #Copy alertmanager-bundle to the server
  -> file { '/tmp/alertmanager.tar.gz':
    ensure => file,
    source => 'puppet:///data/alertmanager.linux-amd64.tar.gz',
    notify => Exec[ 'untar-alertmanager' ],
  }
  #Unpackage alertmanager
  exec { 'untar-alertmanager':
    command     => '/bin/tar -zxf /tmp/alertmanager.tar.gz -C /opt/alertmanager --strip-components=1',
    refreshonly => true,
    user        => 'alertmanager',
  }

  file { '/opt/alertmanager/alertmanager.yml':
    ensure  => file,
    content => template('alertmanager/alertmanager.yaml.erb'),
    notify  => Exec['alertmanager-hup'],
  }
  #Systemctl config
  -> file { '/etc/systemd/system/alertmanager.service':
    ensure  => file,
    content => template('alertmanager/alertmanager.service.erb'),
    notify  => Exec['alertmanager-systemctl-daemon-reload'],
  }
  -> file { '/etc/default/alertmanager':
    ensure  => file,
    content => template('alertmanager/alertmanager.default.erb'),
    notify  => Service['alertmanager'],
  }
  -> apache::proxy { 'alertmanager':
    url     => '/',
    backend => 'http://localhost:9093/',
  }
  -> service { 'alertmanager':
    ensure  => running,
  }

  exec { 'alertmanager-hup':
    command     => '/usr/bin/pkill -SIGHUP alertmanager',
    refreshonly => true,
  }
  exec { 'alertmanager-systemctl-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }
}
