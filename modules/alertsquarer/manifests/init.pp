# Copyright 2023 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: alertsquarer
#
# DHtech alertsquarer, an audio visual experience, fetching alerts from alertmanager
#
# === Parameters
#
# No parameters;
#

class alertsquarer(info) {

  package { ['git', 'build-essentials', 'curl']:
    ensure => installed,
  }

  exec { 'install_nodejs_from_nodesource':
    command => '/bin/bash -c "curl -sL https://deb.nodesource.com/setup_20.x | bash -"',
    path    => ['/bin', '/usr/bin'],
    creates => '/etc/apt/sources.list.d/nodesource.list',
    require => Package['curl'],
  }

  vcsrepo { '/opt/alertsquarer':
    ensure   => latest,
    provider => git,
    source   => 'https://github.com/dhtech/alertsquarer',
    require  => Package['git'],
    notify   => Exec['systemctl-daemon-reload'],
  }
  
  file { '/etc/systemd/system/observer.service':
    ensure  => file,
    content => template('observer/observer.service.erb'),
    notify  => Exec['systemctl-daemon-reload'],
  }

  exec { 'systemctl-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  service { 'alertsquarer-api':
    ensure => running,
    enable => true,
  }
  service { 'alertsquarer-matrix':
    ensure => running,
    enable => true,
  }
  
}
