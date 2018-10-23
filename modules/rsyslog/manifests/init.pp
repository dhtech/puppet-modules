# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: rsyslog
#
# This package manages our rsyslog servers.
#

class rsyslog {

  service { 'rsyslog':
    name => 'rsyslog',
    ensure => 'running',
    enable => true,
  }

  file { 'receiver.conf':
    path    => "/etc/rsyslog.d/receiver.conf",
    ensure  => file,
    content => template("rsyslog/receiver.conf.erb"),
    notify  => Service["rsyslog"],
  }

  file { 'prometheus-syslog-exporter':
    path    => '/usr/local/bin/prometheus-syslog-exporter',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///modules/rsyslog/prometheus-exporter-rsyslog.sh',
  }

  cron { 'prometheus-syslog-exporter-cron':
    command => '/usr/local/bin/prometheus-syslog-exporter > /var/tmp/export/syslog.prom',
    minute  => '*',
    require => [ Service['rsyslog'], File['prometheus-syslog-exporter'] ],
  }
}
