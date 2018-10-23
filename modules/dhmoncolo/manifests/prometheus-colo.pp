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
	ensure	=> 'present',
  }->

  user { 'prometheus':
	ensure	=> 'present',
	system	=> true,
  }->

#Create directories for Prometheus-Colo
  file { '/opt/prometheus-colo':
	ensure	=> 'directory',
	owner	=> 'prometheus',
	group	=> 'prometheus',
	mode	=> '0700',
  }->

  file { '/srv/metrics/prometheus-colo':
	ensure	=> directory,
	owner	=> 'prometheus',
	group	=> 'prometheus',
	mode	=> '0700',
  }->

#Make sure that the tar file is on the server
  file { '/tmp/prometheus.tar.gz':
	source	=> 'puppet:///data/prometheus-2.0.0.linux-amd64.tar.gz',
	ensure	=> file,
  }->

#unpackage Prometheus
  file { 'untar':
	command	=> '/bin/tar -zxvf /tmp/prometheus.tar.gz -C /opt/prometheus-colo --strip-components=1',
	user	=> 'prometheus',
	require	=> File["/opt/prometheus"],
	require	=> File["/tmp/prometheus.tar.gz"],
  }->

#Create systemctl config
  file { '/etc/defaults/prometheus-colo.service':
	content	=> template('dhmoncolo/prometheus-colo.defaults.erb'),
	ensure	=> file,
	notify	=> Exec["systemctl-daemon-reload"],
  }->

  file { '/etc/systemd/system/prometheus-colo.service':
	content	=> template('dhmoncolo/prometheus-colo.service.erb'),
	ensure	=> file,
	notify	=> Exec["systemctl-daemon-reload"],
	notify	=> Exec["systemctl-enable"],
  }->

  file { '/opt/prometheus/prometheus.yml':
	content	=> template('dhmon/prometheus-colo.yaml.erb'),
	ensure	=> file,
	notify	=> exec["prometheus-hup"]
  }->

  service { 'prometheus-colo':
	ensure	=> running,
	require	=> File["/etc/systemd/system/prometheus.service"]
  }

  exec { 'prometheus-hup':
	command		=> '/usr/bin/pkill -SIGHUP prometheus',
	refreshonly	=> true,
  }

  exec { 'systemctl-daemon-reload':
	command		=> '/bin/systemctl daemon-reload',
	refreshonly	=> true,
  }

  exec { 'systemctl-enable':
	command		=> '/bin/systemctl enable prometheus-colo',
	refreshonly	=> true,
  }

  apache::proxy { 'prometheus-backend':
	url		=> '/prometheus/',
	backend	=> 'http://localhost:9090/prometheus/',
  }

}
