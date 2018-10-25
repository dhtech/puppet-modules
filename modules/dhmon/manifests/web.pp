# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: web
#
# Static HTML
#
# === Parameters
#

class dhmon::web {
  file { '/var/www/html/css':
    ensure => 'directory',
  }
  file { '/var/www/html/img':
    ensure => 'directory',
  }
  file { 'index.html':
    ensure => file,
    source => 'puppet:///scripts/dhmon-web/index.html',
    mode   => '0444',
    path   => '/var/www/html/index.html',
  }
  file { 'style.css':
    ensure  => file,
    source  => 'puppet:///scripts/dhmon-web/css/style.css',
    mode    => '0444',
    path    => '/var/www/html/css/style.css',
    require => File['/var/www/html/css']
  }
  file { 'alertmanager.png':
    ensure  => file,
    source  => 'puppet:///scripts/dhmon-web/img/alertmanager.png',
    mode    => '0444',
    path    => '/var/www/html/img/alertmanager.png',
    require => File['/var/www/html/img']
  }
  file { 'dhmap.png':
    ensure  => file,
    source  => 'puppet:///scripts/dhmon-web/img/dhmap.png',
    mode    => '0444',
    path    => '/var/www/html/img/dhmap.png',
    require => File['/var/www/html/img']
  }
  file { 'gafana.png':
    ensure  => file,
    source  => 'puppet:///scripts/dhmon-web/img/gafana.png',
    mode    => '0444',
    path    => '/var/www/html/img/gafana.png',
    require => File['/var/www/html/img']
  }
  file { 'k8s.svg':
    ensure  => file,
    source  => 'puppet:///scripts/dhmon-web/img/k8s.svg',
    mode    => '0444',
    path    => '/var/www/html/img/k8s.svg',
    require => File['/var/www/html/img']
  }

  file { 'webmon':
    path    => '/var/www/html/webmon',
    source  => 'puppet:///scripts/webmon',
    recurse => true,
  }

  file { 'dhmap':
    ensure => link,
    path   => '/var/www/html/dhmap',
    target => '/scripts/dhmap/',
  }

  cron { 'update-seatmap':
    command => '/scripts/dhmap/src/ipplan2dhmap.py /etc/ipplan.db > /var/www/html/dhmap/data.json',
    user    => root,
    minute  => '*/10',
    require => File['dhmap'],
  }
}
