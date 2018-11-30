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
  package { 'python3-pip':
    ensure => installed,
  }
  file { '/etc/voipplan':
    mode   => '0644',
    owner  => 'root',
    group  => 'root:wq',
    source => 'puppet:///svn/allevents/services/voipplan',
  }
  file { '/etc/apache2/sites-available/tele.event.dreamhack.se.conf':
    notify => Exec['a2ensite'],
    mode   => '0644',
    owner  => 'www-data',
    group  => 'www-data',
    source => 'puppet:///modules/telehttp/tele.event.dreamhack.se.conf',
  }
  exec { 'a2ensite':
    refreshonly => true,
    command     => '/usr/sbin/a2ensite tele.event.dreamhack.se',
    creates     => '/etc/apache2/sites-available/.tele_a2ensite_enabled',
    notify      => Service['apache2'],
  }
  exec { 'get-deps':
    command => 'pip3 install -r /scripts/telehttp/app/requirements.txt',
  }
  supervisor::register { 'tele':
    command   => '/usr/bin/python3 /scripts/telehttp/app/app.py'
  }
}
