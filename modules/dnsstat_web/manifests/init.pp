# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: dnsstat_web
#
# dnsstat_web - Display DNS request statistics.
# This module has only been tested on Debian.
#
# === Parameters
#
# [*current_event*]
#   Used for retrieving database credentials of the dnsstatd_{event} database.
#

class dnsstat_web($current_event) {

  $secret_db_dnsstatd   = vault('postgresql:dnsstatd', {})

  ensure_packages([
    'apache2',
    'php',
    'php-pgsql'])

  file { '/etc/apache2/sites-available/dnsstat.event.dreamhack.se.conf':
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/dnsstat_web/dnsstat.event.dreamhack.se.conf',
    notify => Exec['a2ensite_dnsstat'],
  }
  exec { 'a2ensite_dnsstat':
    refreshonly => true,
    require     => Package['apache2'],
    command     => '/usr/sbin/a2ensite dnsstat.event.dreamhack.se',
    creates     => '/etc/apache2/sites-available/.dnsstat_a2ensite_enabled',
    notify      => Exec['dnsstat-apache2-restart'],
  }

  exec { 'dnsstat-apache2-restart':
    command     =>  '/bin/systemctl restart apache2',
    refreshonly => true,
  }

  file { ['/var/www/dnsstat.event.dreamhack.se',
          '/var/www/dnsstat.event.dreamhack.se/public',
          '/var/www/dnsstat.event.dreamhack.se/public/graph',
          '/var/www/dnsstat.event.dreamhack.se/public/graph/js']:
    ensure => directory,
    owner  => 'www-data',
    group  => 'www-data',
  }
  -> file { '/var/www/dnsstat.event.dreamhack.se/generate_json.php':
    ensure  => file,
    content => template('dnsstat_web/generate_json.php.erb'),
    owner   => 'www-data',
    group   => 'www-data',
    mode    => '0600',
  }
  -> file { '/var/www/dnsstat.event.dreamhack.se/public/index.html':
    ensure => file,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => 'puppet:///modules/dnsstat_web/index.html',
  }
  -> file { '/var/www/dnsstat.event.dreamhack.se/public/head.png':
    ensure => file,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => 'puppet:///modules/dnsstat_web/head.png',
  }
  -> file { '/var/www/dnsstat.event.dreamhack.se/public/stats.json':
    ensure => present,
  }
  -> file { '/var/www/dnsstat.event.dreamhack.se/public/graph/index.html':
    ensure => file,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => 'puppet:///modules/dnsstat_web/graph.html',
  }
  -> file { '/var/www/dnsstat.event.dreamhack.se/public/graph/head.png':
    ensure => file,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => 'puppet:///modules/dnsstat_web/graph_head.png',
  }
  -> file { '/var/www/dnsstat.event.dreamhack.se/public/graph/js/amcharts.js':
    ensure => file,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => 'puppet:///modules/dnsstat_web/amcharts.js',
  }
  -> file { '/var/www/dnsstat.event.dreamhack.se/public/graph/js/jquery.js':
    ensure => file,
    owner  => 'www-data',
    group  => 'www-data',
    mode   => '0644',
    source => 'puppet:///modules/dnsstat_web/jquery.js',
  }

  cron { 'generate_statistics_json':
    command => 'php /var/www/dnsstat.event.dreamhack.se/generate_json.php',
    user    => 'root',
    minute  => '*/10',
  }
}
