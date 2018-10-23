# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: dhmon::prometheus
#
# Prometheus metrics collector
#
# === Parameters
#
# [*scrape_configs*]
#   Map of the same structure as Prometheus' scrape_configs.
#

class dhmon::prometheus ($scrape_configs) {

  #Create user/group for Prometheus
  group { 'prometheus':
    ensure => 'present',
  }->
  user { 'prometheus':
   ensure => 'present',
   system => true,
  }->
  #Create directories for prometheus and metric storage
  file { '/opt/prometheus':
   ensure => 'directory',
   owner  => 'prometheus',
   group  => 'prometheus',
   mode   => '0700',
  }->
  file { '/srv/metrics':
    content  => template('dhmon/prometheus.yaml.erb'),
    ensure   => directory,
    owner    => 'prometheus',
    group    => 'prometheus',
    mode     => '0700',
  }->

  #Copy prometheus tar bundle to the server
  file { '/tmp/prometheus.tar.gz':
    source  => 'puppet:///data/prometheus-2.3.0.linux-amd64.tar.gz',
    ensure  => file,
    notify  => Exec[ 'untar-prometheus' ],
  }
  #Unpackage prometheus
  exec { 'untar-prometheus':
    command     => '/bin/tar -zxf /tmp/prometheus.tar.gz -C /opt/prometheus --strip-components=1',
    refreshonly => true,
    user        => 'prometheus',
  }

  file { '/opt/prometheus/prometheus.yml':
    content  => template('dhmon/prometheus.yaml.erb'),
    ensure   => file,
    notify   => Exec['prometheus-hup'],
  }->

  file { '/etc/systemd/system/prometheus.service':
    content => template('dhmon/prometheus.service.erb'),
    ensure  => file,
    notify  => Exec["systemctl-daemon-reload"],
  }->

  file { '/etc/default/prometheus':
    content  => template('dhmon/prometheus.default.erb'),
    ensure   => file,
  }->

  file { 'rules':
    path     => '/opt/prometheus/rules',
    ensure   => directory,
    recurse  => true,
    owner    => 'prometheus',
    group    => 'prometheus',
    purge    => true,
    source   => 'puppet:///svn/allevents/dhmon/rules/',
    notify   => Exec['prometheus-hup'],
  }->

  service { 'prometheus':
    ensure  => running,
    require => File["/etc/systemd/system/prometheus.service"]
  }->

  exec { 'systemctl-enable':
    command     => '/bin/systemctl enable prometheus',
    refreshonly => true,
  }

  exec { 'prometheus-hup':
    command     => '/usr/bin/pkill -SIGHUP prometheus',
    refreshonly => true,
  }

  exec { 'systemctl-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  apache::proxy { 'prometheus-backend':
    url     => '/prometheus/',
    backend => 'http://localhost:9090/prometheus/',
  }

  file { 'prometheus-presence-exporter':
    path    => '/usr/local/bin/prometheus-presence-exporter',
    ensure  => file,
    source  => 'puppet:///modules/dhmon/prometheus-exporter-presence.py',
  }

  cron { 'prometheus-presence-exporter-cron':
    command => '/usr/local/bin/prometheus-presence-exporter > /var/tmp/export/presence.prom',
    minute  => '*',
    require => [ File['prometheus-presence-exporter'] ],
  }

}
