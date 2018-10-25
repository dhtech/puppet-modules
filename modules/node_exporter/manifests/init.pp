# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: node_exporter
#
# Prometheus Node Exporter for dhmon.
#
# === Parameters
#
# No parameters;
#

class node_exporter {
  # Debian 7 doesn't support the systemd config that is in the testing package
  if ($::operatingsystem == 'Debian' and $::operatingsystemmajrelease != '7') or
      $::operatingsystem == 'Ubuntu' {
    if $::operatingsystem == 'Debian' {
      package {
        'prometheus-node-exporter':
          ensure          => installed,
          provider        => apt,
          install_options => ['-t', 'testing'],
      }
    } else {
      package {
        'prometheus-node-exporter':
          ensure   => installed,
          provider => apt,
      }
    }

    package {
      'dbus':
        ensure   => installed,
        provider => apt,
    }
    service {'prometheus-node-exporter':
      ensure  => running,
      enable  => true,
      require => Package['prometheus-node-exporter'],
    }
    file {
      '/var/tmp/export':
        ensure => directory,
        mode   => '1777'
    }
    file {'/etc/default/prometheus-node-exporter':
      content => template('node_exporter/defaults.erb'),
      notify  => Service['prometheus-node-exporter'],
      require => Package['prometheus-node-exporter'],
    }
  }
  # TODO(bluecmd): OpenBSD
}
