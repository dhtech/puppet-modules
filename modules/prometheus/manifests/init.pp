# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: prometheus
#
# Prometheus metrics collector
#
# === Parameters
#
# [*scrape_configs*]
#   Map of the same structure as Prometheus' scrape_configs.
#
# [*current_event*]
#   The current event name, e.g. dhs19
#

class prometheus ($current_event = '', $scrape_configs) {

  #Create user/group for Prometheus
  group { 'prometheus':
    ensure => 'present',
  }
  -> user { 'prometheus':
    ensure => 'present',
    system => true,
  }
  #Create directories for prometheus and metric storage
  -> file { '/opt/prometheus':
    ensure => 'directory',
    owner  => 'prometheus',
    group  => 'prometheus',
    mode   => '0700',
  }
  -> file { '/srv/metrics':
    ensure  => directory,
    content => template('prometheus/prometheus.yaml.erb'),
    owner   => 'prometheus',
    group   => 'prometheus',
    mode    => '0700',
  }

  #Copy prometheus tar bundle to the server
  file { '/tmp/prometheus.tar.gz':
    ensure => file,
    source => 'puppet:///data/prometheus-2.10.0.linux-amd64.tar.gz',
    notify => Exec[ 'untar-prometheus' ],
  }
  #Unpackage prometheus
  exec { 'untar-prometheus':
    command     => '/bin/tar -zxf /tmp/prometheus.tar.gz -C /opt/prometheus --strip-components=1',
    refreshonly => true,
    user        => 'prometheus',
  }

  file { '/opt/prometheus/prometheus.yml':
    ensure  => file,
    content => template('prometheus/prometheus.yaml.erb'),
    notify  => Exec['prometheus-hup'],
  }
  -> file { '/etc/systemd/system/prometheus.service':
    ensure  => file,
    content => template('prometheus/prometheus.service.erb'),
    notify  => Exec['prometheus-systemctl-daemon-reload'],
  }
  -> file { '/etc/default/prometheus':
    ensure  => file,
    content => template('prometheus/prometheus.default.erb'),
    notify  => Service['prometheus'],
  }

  file { 'rules':
    ensure  => directory,
    path    => '/opt/prometheus/rules',
    recurse => true,
    owner   => 'prometheus',
    group   => 'prometheus',
    purge   => true,
    source  => 'puppet:///svn/allevents/prometheus/rules/',
    notify  => Exec['prometheus-hup'],
  }
  file { 'puppet':
    ensure  => directory,
    path    => '/opt/prometheus/external',
    recurse => true,
    owner   => 'prometheus',
    group   => 'prometheus',
    purge   => true,
    source  => 'puppet:///svn/allevents/prometheus/external/',
    notify  => Exec['prometheus-hup'],
  }
  -> service { 'prometheus':
    ensure  => running,
    require => File['/etc/systemd/system/prometheus.service']
  }
  -> exec { 'systemctl-enable':
    command     => '/bin/systemctl enable prometheus',
    refreshonly => true,
  }

  exec { 'prometheus-hup':
    command     => '/usr/bin/pkill -SIGHUP prometheus',
    refreshonly => true,
  }

  exec { 'prometheus-systemctl-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  apache::proxy { 'prometheus-backend':
    url     => '/',
    backend => 'http://localhost:9090/',
  }

  file { 'prometheus-presence-exporter':
    ensure => file,
    path   => '/usr/local/bin/prometheus-presence-exporter',
    source => 'puppet:///modules/prometheus/prometheus-exporter-presence.py',
    mode   => '0755',
  }

  cron { 'prometheus-presence-exporter-cron':
    command => '/usr/local/bin/prometheus-presence-exporter > /var/tmp/export/presence.prom',
    minute  => '*',
    require => [ File['prometheus-presence-exporter'] ],
  }

}
