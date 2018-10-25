# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: nginx
#
# This class manages the nginx
#
#
# === Parameters
#

class nginx {

  $conf_dir = '/etc/nginx/sites-enabled/'
  $tele_www_dir = '/srv/www/tele'
  $rc_name = 'nginx'

  package { 'nginx':
    ensure => installed,
  }

  file { 'tele_www_index':
    ensure  => file,
    path    => "${tele_www_dir}/index.html",
    content => template('nginx/dh-tele-index.html.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  file { 'dh-tele':
    ensure  => file,
    path    => "${conf_dir}/dh-tele",
    content => template('nginx/dh-tele.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  file { 'dh-public-www':
    ensure  => file,
    path    => "${conf_dir}/dh-public-www",
    content => template('nginx/dh-public-www.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  service { 'nginx':
    ensure  => 'running',
    name    => $rc_name,
    enable  => true,
    require => Package['nginx'],
  }
}
