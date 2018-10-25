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


  file { '/opt/prometheus':
  ensure  => 'directory',
  owner  => 'prometheus',
  group  => 'prometheus',
  }

  file { '/tmp/prometheus.tar.gz':
  ensure  => file,
  source  => 'puppet:///data/prometheus-2.0.0.linux-amd64.tar.gz',
  }

  file { 'untar':
  command  => '/bin/tar -zxvf /tmp/prometheus.tar.gz -C /opt/prometheus',
  user    => 'prometheus',
  require  => File['/opt/prometheus'],
  require  => File['/tmp/prometheus.tar.gz'],
  }

  # Fix variable to get what instance prometheus is running, eg colo/event
  file { '/etc/systemd/system/prometheus.service':
  ensure  => file,
  content  => template('dhmoncolo/prometheus.service.erb'),
  notify  => Exec['systemctl-daemon-reload'],
  }

  file { '/opt/prometheus/prometheus.yml':
  ensure  => file,
  content  => template('dhmon/prometheus.yaml.erb'),
  }

  file { '/srv/metrics/prometheus':
  ensure  => directory,
  owner  => 'prometheus',
  group  => 'prometheus',
  mode   => '0700',
  }
  -> service { 'prometheus':
  ensure  => running,
  }

file { 'rules':
  path    => '/opt/prometheus/rules',
  ensure  => directory,
  recurse  => true,
  purge   => true,
  source  => 'puppet:///svn/allevents/dhmon/colo-rules/',
  notify  => Exec['prometheus-hup'],
 }

  exec { 'prometheus-hup':
  command     => '/usr/bin/pkill -SIGHUP prometheus',
  refreshonly  => true,
  }

  apache::proxy { 'prometheus-backend':
  url     => '/prometheus/',
  backend  => 'http://localhost:9090/prometheus/',
  }

}
