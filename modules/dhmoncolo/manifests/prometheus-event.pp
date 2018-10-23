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


  file { '/opt/prometheus-event':
	ensure	=> 'directory',
	owner	=> 'prometheus',
	group	=> 'prometheus',
  }

  file { '/tmp/prometheus.tar.gz':
	source	=> 'puppet:///data/prometheus-2.0.0.linux-amd64.tar.gz',
	ensure	=> file,
  }

  file { 'untar':
	command	=> '/bin/tar -zxvf /tmp/prometheus.tar.gz -C /opt/prometheus-event',
	user	=> 'prometheus',
	require	=> File["/opt/prometheus-event"],
	require	=> File["/tmp/prometheus.tar.gz"],
  }

  # Fix variable to get what instance prometheus is running, eg colo/event
  file { '/etc/systemd/system/prometheus-event.service':
	content	=> template('dhmoncolo/prometheus-event.service.erb'),
	ensure	=> file,
	notify	=> Exec["systemctl-daemon-reload"],
  }

  file { '/opt/prometheus-event/prometheus.yml':
	content	=> template('dhmon/prometheus-event.yaml.erb'),
	ensure	=> file,
  }

  file { '/srv/metrics/prometheus-event':
	ensure	=> directory,
	owner	=> 'prometheus',
	group	=> 'prometheus',
	mode	=> '0700',
  }->

  service { 'prometheus':
	ensure	=> running,
  }

  exec { 'prometheus-hup':
	command		=> '/usr/bin/pkill -SIGHUP prometheus-event',
	refreshonly	=> true,
  }

  apache::proxy { 'prometheus-backend':
	url		=> '/prometheus-event/',
	backend	=> 'http://localhost:9094/prometheus-event/',
  }

}
