# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: request
#
# Deploys a request instance
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#

class request {
  $dhid   = vault('app:request.tech.dreamhack.se', {})
  $dbname = 'request.tech.dreamhack.se'
  $db     = vault("postgresql:${dbname}", {})

  ensure_packages([
    'apache2', 'php', 'php-cli', 'libapache2-mod-php', 'php-gd', 'php-xml',
    'php-mbstring', 'php-pgsql'
  ])

  user { 'deployer':
    ensure => present,
    name   => 'deployer',
    home   => '/home/deployer',
  }

  service { 'apache2':
    ensure => running,
  }

  file { 'install_composer.sh':
    ensure => 'file',
    source => 'puppet:///scripts/request/install_composer.sh',
    path   => '/usr/local/bin/install_composer.sh',
    owner  => 'root',
    group  => 'root',
    mode   => '0744', # Use 0700 if it is sensitive
  }

  exec { 'install_composer':
    command => '/usr/local/bin/install_composer.sh',
    creates => '/usr/local/bin/composer',
    require => File['install_composer.sh'],
  }

  file { '/etc/apache2/sites-available/request.tech.dreamhack.se.conf':
    notify  => Exec['a2ensite'],
    mode    => '0644',
    owner   => 'www-data',
    group   => 'www-data',
    content => template('request/request.tech.dreamhack.se.conf.erb'),
  }

  exec { 'a2ensite':
    refreshonly => true,
    path        => [ '/bin', '/usr/bin', '/usr/sbin' ],
    command     => 'a2ensite request.tech.dreamhack.se.conf',
    creates     => '/etc/apache2/sites-enabled/request.tech.dreamhack.se.conf',
    notify      => Service['apache2'],
    require     => File['/var/www/request.tech.dreamhack.se'],
  }

  file { '/var/www/request.tech.dreamhack.se':
    ensure  => directory,
    mode    => '0755',
    owner   => 'deployer',
    group   => 'www-data',
    require => Package['apache2'],
  }

  file { '/var/www/request.tech.dreamhack.se/releases':
    ensure  => directory,
    mode    => '0755',
    owner   => 'deployer',
    group   => 'deployer',
    require => File['/var/www/request.tech.dreamhack.se'],
  }

  file { '/var/www/request.tech.dreamhack.se/storage':
    ensure  => directory,
    mode    => '0755',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/www/request.tech.dreamhack.se'],
  }

  file { '/var/www/request.tech.dreamhack.se/storage/app':
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File['/var/www/request.tech.dreamhack.se/storage'],
  }

  file { '/var/www/request.tech.dreamhack.se/storage/debugbar':
    ensure  => directory,
    mode    => '0755',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/www/request.tech.dreamhack.se/storage'],
  }

  file { '/var/www/request.tech.dreamhack.se/storage/framework':
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File['/var/www/request.tech.dreamhack.se/storage'],
  }

  file { '/var/www/request.tech.dreamhack.se/storage/framework/cache':
    ensure  => directory,
    mode    => '0755',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/www/request.tech.dreamhack.se/storage/framework'],
  }

  file { '/var/www/request.tech.dreamhack.se/storage/framework/sessions':
    ensure  => directory,
    mode    => '0755',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/www/request.tech.dreamhack.se/storage/framework'],
  }

  file { '/var/www/request.tech.dreamhack.se/storage/framework/views':
    ensure  => directory,
    mode    => '0755',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/www/request.tech.dreamhack.se/storage/framework'],
  }

  file { '/var/www/request.tech.dreamhack.se/storage/logs':
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File['/var/www/request.tech.dreamhack.se/storage'],
  }

  file { '/var/www/request.tech.dreamhack.se/cache':
    ensure  => directory,
    mode    => '0755',
    owner   => 'www-data',
    group   => 'www-data',
    require => File['/var/www/request.tech.dreamhack.se'],
  }
  if ($dhid != {} and $db != {}) {
    file { 'env':
      ensure  => 'file',
      path    => '/var/www/request.tech.dreamhack.se/.env',
      owner   => 'deployer',
      group   => 'www-data',
      mode    => '0740', # Use 0700 if it is sensitive
      content => template('request/env.erb'),
      require => File['/var/www/request.tech.dreamhack.se'],
    }
  }
  exec { 'a2enmod_rewrite':
    command => '/usr/sbin/a2enmod rewrite',
    creates => '/etc/apache2/mods-enabled/rewrite.load',
    require => Package['apache2'],
    notify  => Service['apache2'],
  }


}
