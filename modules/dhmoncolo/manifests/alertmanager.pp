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

class dhmon::alertmanager {

  file { '/opt/alertmanager':
	ensure	=> 'directory',
	owner	=> 'prometheus',
	group	=> 'prometheus',
  }

  file { '/tmp/alertmanager.tar.gz':
	source	=> 'puppet:///data/alertmanager-0.7.1.linux-amd64.tar.gz',
	ensure	=> file,
  }

  file { 'untar':
	command	=> '/bin/tar -zxvf /tmp/alertmanager.tar.gz -C /opt/alertmanager',
	user	=> 'prometheus',
	require	=> File["/opt/alertmanager"],
	require => File["/tmp/alertmanager.tar.gz"],
  }

  file { '/opt/alertmanager.yml':
	content	=> template('dhmon/alertmanager.yaml.erb'),
	ensure	=> file,
  }

  file { '/etc/systemd/system/alertmanager.service':
	content	=> template('dhmoncolo/alertmanager.service.erb'),
	ensure	=> file,
	notify	=> Exec["systemctl-daemon-reload"],
  }

  exec { 'systemctl-daemon-reloadi':
	command	=> '/bin/systemctl daemon-reload',
  }

  apache::proxy { 'alertmanager':
	url		=> '/alertmanager',
	backend	=> 'http://localhost:9093/alertmanager',
  }
}
