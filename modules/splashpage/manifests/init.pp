# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: splashpage
#
# Splashpage to be displayed to participants
#

class splashpage {

  package { 'apache2':
    ensure => installed,
  }

  package { 'php5':
    ensure => installed,
  }
  service { 'apache2':
    ensure => running,
  }

  exec { 'a2enmod_php5':
    command => '/usr/sbin/a2enmod php5',
    creates => '/etc/apache2/mods-enabled/php5.load',
    require => Package['apache2', 'php5'],
    notify  => Service['apache2'],
  }

  file { '/var/www/html':
    path    => '/var/www/html/',
    ensure  => directory,
    require => Package['apache2'],
  }

  file { "/var/www/html/index.php":
    source  => "puppet:///scripts/splashpage/public/index.php",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => File['/var/www/html/'],
  }

  file { "/var/www/html/eurostile.ttf":
    source  => "puppet:///scripts/splashpage/public/eurostile.ttf",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => File['/var/www/html/'],
  }

  file { "/var/www/html/favicon-32x32.png":
    source  => "puppet:///scripts/splashpage/public/favicon-32x32.png",
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => File['/var/www/html/'],
  }

  file { "/var/www/html/index.html":
    ensure  => absent,
  }
}
