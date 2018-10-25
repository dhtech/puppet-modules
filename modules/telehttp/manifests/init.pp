# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: telehttp 
#
# TFTP boot content and application deploy module
#
# === Parameters
#
#

class telehttp() {

  ensure_packages(['apache2'])

  service { 'apache2':
    ensure  => running,
  }

  file { '/etc/apache2/sites-available/tele.event.dreamhack.se.conf':
    notify => Exec['a2ensite'],
    mode   => '0644',
    owner    => 'www-data',
    group    => 'www-data',
    source => 'puppet:///modules/telehttp/tele.event.dreamhack.se.conf',
  }
  exec { 'a2ensite':
    refreshonly => true,
    command     => '/usr/sbin/a2ensite tele.event.dreamhack.se',
    creates      => '/etc/apache2/sites-available/.tele_a2ensite_enabled',
    notify      => Service['apache2'],
  }
  file { '/var/www/tele.event.dreamhack.se':
    ensure    => directory,
  }
  file { '/var/www/tele.event.dreamhack.se/index.html':
    ensure    => present,
    mode    => '0644',
    owner   => 'www-data',
    group   => 'www-data',
    notify    => Service['apache2'],
    source    => 'puppet:///modules/telehttp/index.html',
    require => File['/var/www/tele.event.dreamhack.se'],
  }
  file { '/var/www/tele.event.dreamhack.se/tele.css':
    ensure    => present,
    mode    => '0644',
    owner   => 'www-data',
    group   => 'www-data',
    source    => 'puppet:///modules/telehttp/tele.css',
    require => File['/var/www/tele.event.dreamhack.se'],
  }
}
