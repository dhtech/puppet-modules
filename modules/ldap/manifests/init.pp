# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: ldap
#
# LDAP replicated server.
#
# === Parameters
#
# [*master*]
#   Master to connect to for replication
#

class ldap ($master) {
  include stdlib::stages

  # We want to run before 'ldaplogin' and other
  class {
    'ldap::setup':
      stage  => 'setup',
      master => $master;
  }

  # TODO(klump) Make this a real exporter which can run as often as prometheus
  # polls.
  file { 'prometheus-ldapsync-exporter':
    ensure => file,
    path   => '/usr/local/bin/prometheus-ldapsync-exporter',
    mode   => '0755',
    source => 'puppet:///modules/ldap/prometheus-exporter-ldapsync.sh',
  }

  cron { 'prometheus-syslog-exporter-cron':
    command => '/usr/local/bin/prometheus-ldapsync-exporter',
    minute  => '*',
    require => [ File['prometheus-ldapsync-exporter'] ],
  }
}
