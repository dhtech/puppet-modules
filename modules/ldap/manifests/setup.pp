# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# Setup LDAP replication

class ldap::setup ($master) {
  ensure_packages(['python3'])

  file { 'dh-ldap-replication':
    ensure  => file,
    path    => '/usr/bin/dh-ldap-replication',
    mode    => '0755',
    source  => 'puppet:///modules/ldap/dh-ldap-replication.sh',
    require => [Package['slapd']],
  }

  file { 'slapd-default':
    ensure  => file,
    path    => '/etc/default/slapd',
    content => template('ldap/slapd.erb'),
    require => [Package['slapd']],
  }

  file { '/var/local/slapd.preseed':
    source => 'puppet:///modules/ldap/slapd.preseed',
    mode   => '0600',
  }
  package { 'slapd':
    ensure       => installed,
    responsefile => '/var/local/slapd.preseed',
    require      => File['/var/local/slapd.preseed'],
  }

  # This is a complex action, use a "run once" script for this
  exec { 'setup-replication':
    command => "/usr/bin/dh-ldap-replication ${master}",
    require => [File['slapd-default'], File['dh-ldap-replication']],
    creates => '/etc/ldap/replication.configured',
  }
}
