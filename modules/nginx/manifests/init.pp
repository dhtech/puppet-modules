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
    path    => "$tele_www_dir/index.html",
    ensure  => file,
    content => template('nginx/dh-tele-index.html.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  file { 'dh-tele':
    path    => "$conf_dir/dh-tele",
    ensure  => file,
    content => template('nginx/dh-tele.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  file { 'dh-public-www':
    path    => "$conf_dir/dh-public-www",
    ensure  => file,
    content => template('nginx/dh-public-www.conf.erb'),
    notify  => Service['nginx'],
    require => Package['nginx'],
  }

  service { 'nginx':
    name => "$rc_name",
    ensure => 'running',
    enable => true,
    require => Package['nginx'],
  }
}
