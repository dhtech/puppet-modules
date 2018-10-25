# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: puppetdb
#
# This package manages puppetdb. For now only the textfile collecter though.
#

class puppetdb {

  file { 'prometheus-puppetdb-exporter':
    ensure => file,
    path   => '/usr/local/bin/prometheus-puppetdb-exporter',
    mode   => '0755',
    source => 'puppet:///modules/puppetdb/prometheus-exporter-puppetdb.py',
  }

  cron { 'prometheus-puppetdb-exporter-cron':
    command => '/usr/local/bin/prometheus-puppetdb-exporter > /var/tmp/export/puppetdb.prom',
    minute  => '*',
    require => [ File['prometheus-puppetdb-exporter'] ],
  }
}
