# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: promtail
#
# Promtail for loki
#
# === Parameters
#
# No parameters;
#

class promtail($loki_uris) {

  # Create directories for promtail
  file { '/opt/promtail':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  # Copy promtail-bundle to the server and extract
  file { '/opt/promtail/promtail.gz':
    ensure => file,
    source => "puppet:///data/promtail-1.0.0.linux-${::facts['os']['architecture']}.gz",
    notify => Exec['extract-promtail'],
  }
  exec { 'extract-promtail':
    command     => 'rm -f /opt/promtail/promtail; gunzip -nk /opt/promtail/promtail.gz && chmod +x /opt/promtail/promtail',
    refreshonly => true,
    user        => 'root',
    path        => ['/bin', '/usr/bin'],
    notify      => Service['promtail'],
  }

  # Promtail configuration file
  file { '/opt/promtail/promtail.yml':
    ensure  => file,
    content => template('promtail/promtail.yml.erb'),
    notify  => Service['promtail'],
  }
  file { '/etc/default/promtail':
    ensure  => file,
    content => template('promtail/promtail.default.erb'),
    notify  => Service['promtail'],
  }

  file { '/etc/systemd/system/promtail.service':
    ensure  => file,
    content => template('promtail/promtail.service.erb'),
    notify  => Exec['promtail-systemctl-daemon-reload'],
  }
  exec { 'promtail-systemctl-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  service { 'promtail':
    ensure => running,
    enable => true,
  }

}
