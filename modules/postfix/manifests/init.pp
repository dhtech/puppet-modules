# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: postfix
#
# This module manages the rancid server which fetches and saves configuration
# in the core and dist service.
#
# === Parameters
#
# [*mailer_type*]
#   Decides how postfix will be used. The default is "local" which only listens on localhost
#

class postfix($mailer_type = 'local', $relay_host = '[mail.tech.dreamhack.se]') {

  package { 'postfix':
    ensure => installed,
  }

  file { 'main.cf':
    ensure  => file,
    path    => '/etc/postfix/main.cf',
    content => template('postfix/main.cf.erb'),
    notify  => Service['postfix'],
    require => Package['postfix'],
  }

  service { 'postfix':
    ensure  => 'running',
    name    => 'postfix',
    enable  => true,
    require => Package['postfix'],
  }

}
