# Copyright 2024 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: netbox
#
# Deploys a netbox instance
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
class netbox {
  include stdlib
  $servername = $::fqdn
  $appsecrets = vault("app:${servername}", {})
  $db         = vault("postgresql:${servername}", {})

  ensure_packages([
    'git', 'nginx', 'redis-server',
    'python3', 'python3-pip', 'python3-venv', 'python3-dev', 'build-essential',
    'libxml2-dev', 'libxslt1-dev', 'libffi-dev', 'libpq-dev', 'libssl-dev', 'zlib1g-dev',
    'libldap2-dev', 'libsasl2-dev'
  ])

  group { 'netbox':
    ensure => present,
    name   => 'netbox',
  }

  user { 'netbox':
    ensure => present,
    name   => 'netbox',
    home   => '/opt/netbox',
    gid    => 'netbox',
  }

  file { '/opt/netbox':
    ensure => directory,
    mode   => '0755',
    owner  => 'netbox',
    group  => 'netbox',
  }

  service { 'nginx':
    ensure => running,
  }

  file { 'nginx_netbox_site':
    ensure  => 'file',
    path    => '/etc/nginx/sites-available/netbox',
    mode    => '0640',
    content => template('netbox/nginx_site.erb'),
    notify  => Service['nginx'],
  }
  file { '/etc/nginx/sites-enabled/netbox':
    ensure => link,
    target => '/etc/nginx/sites-available/netbox',
    notify => Service['nginx'],
  }

  # Needed for 'ssl-cert' group
  ensure_packages(['ssl-cert'])

  file { '/etc/ssl/certs/server-fullchain.crt':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0644',
    source => 'puppet:///letsencrypt/fullchain.pem',
    links  => 'follow',
    notify => Service['nginx'],
  }

  file { '/etc/ssl/private/server.key':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0640',
    source => 'puppet:///letsencrypt/privkey.pem',
    links  => 'follow',
    notify => Service['nginx'],
  }

  exec { 'clone netbox':
    command => '/usr/bin/git clone https://github.com/netbox-community/netbox.git /opt/netbox',
    creates => '/opt/netbox/.git',
    timeout => 600,
    require => File['/opt/netbox'],
  }

  if ($appsecrets != {} and $db != {}) {
    file { 'configuration.py':
      ensure  => 'file',
      path    => '/opt/netbox/netbox/netbox/configuration.py',
      owner   => 'netbox',
      group   => 'netbox',
      mode    => '0740', # Use 0700 if it is sensitive
      content => template('netbox/configuration.erb'),
      require => Exec['clone netbox'],
    }
  }
  file { 'gunicorn.py':
    ensure  => 'file',
    path    => '/opt/netbox/gunicorn.py',
    owner   => 'netbox',
    group   => 'netbox',
    mode    => '0740', # Use 0700 if it is sensitive
    content => template('netbox/gunicorn.erb'),
    require => Exec['clone netbox'],
  }
  file { 'ldap_config.py':
    ensure  => 'file',
    path    => '/opt/netbox/netbox/netbox/ldap_config.py',
    owner   => 'netbox',
    group   => 'netbox',
    mode    => '0740', # Use 0700 if it is sensitive
    content => template('netbox/ldap_config.py.erb'),
    require => Exec['clone netbox'],
  }
  file { 'local_requirements.txt':
    ensure  => 'file',
    path    => '/opt/netbox/local_requirements.txt',
    owner   => 'netbox',
    group   => 'netbox',
    mode    => '0740', # Use 0700 if it is sensitive
    content => template('netbox/local_requirements.txt.erb'),
    require => Exec['clone netbox'],
  }

  file { '/etc/systemd/system/netbox.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('netbox/netbox.service.erb'),
  }

  file { '/etc/systemd/system/netbox-rq.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('netbox/netbox-rq.service.erb'),
  }

  file { '/etc/systemd/system/housekeeping.service':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('netbox/housekeeping.service.erb'),
  }

  exec { 'reload_systemd':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
    subscribe   => [
      File['/etc/systemd/system/netbox.service'],
      File['/etc/systemd/system/netbox-rq.service'],
      File['/etc/systemd/system/housekeeping.service'],
      ],
    notify      => [Service['netbox'], Service['netbox-rq']],
  }

  service { 'netbox':
    ensure => running,
    enable => true,
  }
  service { 'netbox-rq':
    ensure => running,
    enable => true,
  }
}
