# Copyright 2019 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: mailmx
#
# This module manages the rancid server which fetches and saves configuration
# in the core and dist service.
#
# === Parameters
#
# [*postfix_networks*]
#   Decides how postfix will be used.
# [*postfix_destinations*]
#   Decides how postfix will be used.
#

class mailmx($ldap_uri, $postfix_networks, $postfix_destinations) {

  #
  # Postfix
  #
  package { ['postfix', 'postfix-ldap', 'postfix-sqlite']:
    ensure => installed,
  }

  file { '/etc/postfix/main.cf':
    ensure  => file,
    content => template('mailmx/postfix/main.cf.erb'),
    notify  => Service['postfix'],
    require => Package['postfix'],
  }

  file { '/etc/postfix/dynamicmaps.cf':
    ensure  => file,
    content => template('mailmx/postfix/dynamicmaps.cf.erb'),
  }

  file { '/etc/postfix/ldap-lists-stage1.cf':
    ensure  => file,
    content => template('mailmx/postfix/ldap-lists-stage1.cf.erb'),
  }

  file { '/etc/postfix/ldap-lists-stage2.cf':
    ensure  => file,
    content => template('mailmx/postfix/ldap-lists-stage2.cf.erb'),
  }

  file { '/etc/postfix/ldap-people.cf':
    ensure  => file,
    content => template('mailmx/postfix/ldap-people.cf.erb'),
  }

  file { '/etc/postfix/pfix-no-srs.cf':
    ensure  => file,
    content => template('mailmx/postfix/pfix-no-srs.cf.erb'),
    notify  => Exec['postmap-pfix-no-srs'],
  }

  exec { 'postmap-pfix-no-srs':
    refreshonly => true,
    command     => '/usr/sbin/postmap /etc/postfix/pfix-no-srs.cf',
  }

  file { '/etc/postfix/transport':
    ensure  => file,
    content => template('mailmx/postfix/transport.erb'),
    notify  => Exec['postmap-transport'],
  }

  exec { 'postmap-transport':
    refreshonly => true,
    command     => '/usr/sbin/postmap /etc/postfix/transport',
  }

  service { 'postfix':
    ensure  => 'running',
    name    => 'postfix',
    enable  => true,
    require => Package['postfix'],
  }

  #
  # Dovecot
  #
  package { ['dovecot-core', 'dovecot-imapd']:
    ensure => installed,
  }

  file { '/etc/dovecot/dovecot.conf':
    ensure  => file,
    content => template('mailmx/dovecot/dovecot.conf.erb'),
    notify  => Service['dovecot'],
  }

  file { '/etc/pam.d/dovecot':
    ensure  => file,
    content => template('mailmx/dovecot/dovecot.pam.erb'),
  }

  service { 'dovecot':
    ensure  => 'running',
    name    => 'dovecot',
    enable  => true,
    require => Package['dovecot-core'],
  }

}
