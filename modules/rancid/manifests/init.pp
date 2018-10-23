# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: rancid
#
# This module manages the rancid server which fetches and saves configuration
# in the core and dist service.
#
# === Parameters
#
# [*current_event*]
#   The current event name, e.g. dhs15
#
# [*router_db_lines*]
#   The list of lines that should be added to router.db
#

class rancid($current_event = '', $router_db_lines = []) {

  $readonly = vault('source:readonly')
  $username = $readonly['username']
  $password = $readonly['password']

  $rancid_secret = vault('login:backup')
  $rancid_user = $rancid_secret['username']
  $rancid_password = $rancid_secret['password']
  #Debuging the vault username/password gatherer
  #$rancid_user = backup
  #$rancid_password = yD7sXVmFwgmdvfgdHJ33

  package { 'rancid':
    ensure => installed,
  }

  package { 'subversion':
    ensure => installed,
  }

  user { 'rancid':
    name   => 'rancid',
    home   => '/var/lib/rancid',
    ensure => present,
    require => Package['rancid'],
  }

  file { 'rancid.conf':
    path    => '/etc/rancid/rancid.conf',
    ensure  => file,
    content => template('rancid/rancid.conf.erb'),
    require => Package['rancid'],
  }

  file { '/var/lib/rancid/.subversion':
    ensure  => directory,
    owner   => "rancid",
    group   => "rancid",
    mode    => '0750',
    require => User['rancid'],
  }

  file { '/var/lib/rancid/.subversion/auth':
    ensure  => directory,
    owner   => "rancid",
    group   => "rancid",
    mode    => '0750',
    require => File['/var/lib/rancid/.subversion'],
  }

  file { '/var/lib/rancid/.subversion/auth/svn.simple':
    ensure  => directory,
    owner   => "rancid",
    group   => "rancid",
    mode    => '0750',
    require => File['/var/lib/rancid/.subversion/auth'],
  }

  # The filename of this file is an md5 hash of the "svn:realmstring" which currently is:
  # <https://doc.tech.dreamhack.se:443> Dreamhack network conf Subversion Repository
  #
  # e.g:
  # $ echo -n '<https://doc.tech.dreamhack.se:443> Dreamhack network conf Subversion Repository' | md5sum
  # 7ca2d15a7b1a01e62c9ca3fc9f84cf2c  -
  file { 'subversion-auth-file':
    path    => '/var/lib/rancid/.subversion/auth/svn.simple/7ca2d15a7b1a01e62c9ca3fc9f84cf2c',
    ensure  => file,
    owner   => "rancid",
    group   => "rancid",
    mode    => '0640',
    content => template('rancid/subversion-auth-file.erb'),
    require => [ User['rancid'],
                 Exec['rancid-event-checkout'],
                 File['/var/lib/rancid/.subversion/auth/svn.simple'],
               ],

  }

  file { '.clogin.rc':
    path    => '/var/lib/rancid/.cloginrc',
    owner   => 'rancid',
    group   => 'rancid',
    mode    => '0640',
    ensure  => file,
    content => template('rancid/cloginrc.conf.erb'),
    require => [ Package['rancid'], User['rancid'] ],
  }

  file { 'router.db':
    path    => "/var/lib/rancid/$current_event/router.db",
    owner   => 'rancid',
    group   => 'rancid',
    ensure  => file,
    content => template('rancid/router.db.erb'),
    require => [ Package['rancid'], User['rancid'], Exec['rancid-event-checkout'] ],
  }

  file_line { 'aliases_rancid-admin-dreamhack':
    path   => '/etc/aliases',
    line   => "rancid-admin-$current_event: noc@tech.dreamhack.se",
    notify => Exec['postalias'],
  }

  file_line { 'aliases_rancid-current_event':
    path   => '/etc/aliases',
    line   => "rancid-$current_event:       noc@tech.dreamhack.se",
    notify => Exec['postalias'],
  }

  exec {'postalias':
    command => '/usr/sbin/postalias /etc/aliases',
    refreshonly => true
  }

  exec {'rancid-event-checkout':
    command => "/usr/bin/svn co --non-interactive --username ${username} --password ${password} https://doc.tech.dreamhack.se/netconf/$current_event /var/lib/rancid/$current_event",
    creates => "/var/lib/rancid/$current_event",
    require => Package['rancid'],
    notify  => [ Exec['rancid-lib-perms'], Exec['rancid-log-perms'] ],
  }

  exec {'rancid-lib-perms':
    command     => '/bin/chown rancid:rancid -R /var/lib/rancid',
    refreshonly => true,
    require     => [ Package['rancid'], User['rancid'] ],
  }

  exec {'rancid-log-perms':
    command     => '/bin/chown rancid:rancid -R /var/log/rancid',
    refreshonly => true,
    require     => [ Package['rancid'], User['rancid'] ],
  }

  file { 'rancid-configs':
    path    => "/var/lib/rancid/$current_event/configs",
    owner   => 'rancid',
    group   => 'rancid',
    ensure  => directory,
    require => Exec['rancid-event-checkout'],
    notify  => Exec['rancid-configs-add'],
  }

  exec { 'rancid-configs-add':
    command => "/usr/bin/svn add /var/lib/rancid/$current_event/configs && /usr/bin/svn commit -m \"add configs directory for $current_event\"",
    cwd => "/var/lib/rancid/$current_event/",
    require => File['rancid-configs'],
    user    => 'rancid',
    refreshonly => true,
  }

  file { 'rancid-routers.all':
    path    => "/var/lib/rancid/$current_event/routers.all",
    owner   => 'rancid',
    group   => 'rancid',
    ensure  => file,
    require => Exec['rancid-event-checkout'],
  }

  file { 'rancid-routers.down':
    path    => "/var/lib/rancid/$current_event/routers.down",
    owner   => 'rancid',
    group   => 'rancid',
    ensure  => file,
    require => Exec['rancid-event-checkout'],
  }

  file { 'rancid-routers.up':
    path    => "/var/lib/rancid/$current_event/routers.up",
    owner   => 'rancid',
    group   => 'rancid',
    ensure  => file,
    require => Exec['rancid-event-checkout'],
  }

  cron { 'rancid-run':
    command => 'sudo -u rancid /usr/bin/rancid-run',
    minute  => '*/30',
    require => [ Package['rancid'], User['rancid'] ],
  }

  cron { 'prometheus-rancid-exporter-cron':
    command => '/usr/local/bin/prometheus-exporter-rancid',
    minute  => '*',
    require => [ Package['rancid'], User['rancid'], File['prometheus-rancid-exporter'] ],
  }

  file { 'prometheus-rancid-exporter':
    path    => '/usr/local/bin/prometheus-exporter-rancid',
    content => template('rancid/prometheus-exporter-rancid.erb'),
    ensure  => file,
    mode    => '0755',
  }

  package { 'virtualenv':
    ensure => installed,
  }

  exec { 'prometheus-exporter-distconfcheck-venv':
    command => '/usr/bin/virtualenv /var/local/prometheus-exporter-distconfcheck-venv; /var/local/prometheus-exporter-distconfcheck-venv/bin/pip install ciscoconfparse',
    require => Package['virtualenv'],
    unless => '/usr/bin/test -d /var/local/prometheus-exporter-distconfcheck-venv',
  }

  file { '/usr/local/bin/prometheus-exporter-distconfcheck':
    content => template('rancid/prometheus-exporter-distconfcheck.erb'),
    ensure  => file,
    mode    => '0755',
    require => Exec['prometheus-exporter-distconfcheck-venv'],
  }

  cron { 'prometheus-exporter-distconfcheck':
    command => '/var/local/prometheus-exporter-distconfcheck-venv/bin/python /usr/local/bin/prometheus-exporter-distconfcheck',
    minute => '*',
    require => File['/usr/local/bin/prometheus-exporter-distconfcheck'],
  }
}
