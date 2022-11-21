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
#   Used for setting the name of the thanos bucket database.
#


class prometheus ($scrape_configs, $current_event) {
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
    source => 'puppet:///data/prometheus.linux-amd64.tar.gz',
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
    notify  => Service['prometheus'],
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
    notify  => Service['prometheus'],
  }
  file { 'puppet':
    ensure  => directory,
    path    => '/opt/prometheus/external',
    recurse => true,
    owner   => 'prometheus',
    group   => 'prometheus',
    purge   => true,
    source  => 'puppet:///svn/allevents/prometheus/external/',
    notify  => Service['prometheus'],
  }
  -> service { 'prometheus':
    ensure  => running,
    enable  => true,
    require => File['/etc/systemd/system/prometheus.service']
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

  #
  # Thanos sidecar (upload prometheus data to S3 bucket on colo)
  #
  #Create directories for thanos
  -> file { '/opt/thanos':
    ensure => 'directory',
    owner  => 'prometheus',
    group  => 'prometheus',
    mode   => '0700',
  }

  #Copy prometheus tar bundle to the server
  file { '/tmp/thanos.tar.gz':
    ensure => file,
    source => 'puppet:///data/thanos-0.23.1.linux-amd64.tar.gz',
    notify => Exec[ 'untar-thanos' ],
  }
  #Unpackage thanos
  exec { 'untar-thanos':
    command     => '/bin/tar -zxf /tmp/thanos.tar.gz -C /opt/thanos --strip-components=1',
    refreshonly => true,
    user        => 'prometheus',
  }


  $thanos_s3 = vault('thanos:bucket', {})
  file { '/opt/thanos/bucket.yml':
    ensure  => file,
    content => template('prometheus/bucket.yaml.erb'),
    notify  => Service['thanos-sidecar'],
  }
  -> file { '/etc/systemd/system/thanos-sidecar.service':
    ensure  => file,
    content => template('prometheus/thanos-sidecar.service.erb'),
    notify  => Exec['prometheus-systemctl-daemon-reload'],
  }
  -> file { '/etc/default/thanos':
    ensure  => file,
    content => template('prometheus/thanos.default.erb'),
    notify  => [ Service['thanos-sidecar'] ],
  }

  service { 'thanos-sidecar':
    ensure  => running,
    enable  => true,
    require => File['/etc/systemd/system/thanos-sidecar.service']
  }
}
