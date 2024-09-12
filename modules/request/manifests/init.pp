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
  include stdlib

  $dhid    = vault("app:${::fqdn}", {})
  $dbname  = $::fqdn
  $db      = vault("postgresql:${dbname}", {})
  $webroot = "/var/www/${::fqdn}"

  ensure_packages([
    'apache2', 'php', 'php-cli', 'libapache2-mod-php', 'php-gd', 'php-xml',
    'php-mbstring', 'php-pgsql', 'php-curl', 'php8.2-imagick', 'ghostscript'
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

  file { "/etc/apache2/sites-available/${::fqdn}.conf":
    notify  => Exec['a2ensite'],
    mode    => '0644',
    owner   => 'www-data',
    group   => 'www-data',
    content => template('request/request.tech.dreamhack.se.conf.erb'),
    require => [
      File['/etc/ssl/certs/server-fullchain.crt'],
      File['/etc/ssl/private/server.key']
    ],
  }

  exec { 'a2enmod php8.2':
    path    => [ '/bin', '/usr/bin', '/usr/sbin' ],
    command => 'a2enmod php8.2',
    creates => '/etc/apache2/mods-enabled/php8.2.conf',
    notify  => Service['apache2'],
    require => Package['apache2'],
  }

  exec { 'a2enmod ssl':
    path    => [ '/bin', '/usr/bin', '/usr/sbin' ],
    command => 'a2enmod ssl',
    creates => '/etc/apache2/mods-enabled/ssl.conf',
    notify  => Service['apache2'],
    require => Package['apache2'],
  }

  exec { 'a2ensite':
    path    => [ '/bin', '/usr/bin', '/usr/sbin' ],
    command => "a2ensite ${::fqdn}.conf",
    creates => "/etc/apache2/sites-enabled/${::fqdn}.conf",
    notify  => Service['apache2'],
    require => File[$webroot],
  }

  file { $webroot:
    ensure  => directory,
    mode    => '0755',
    owner   => 'deployer',
    group   => 'www-data',
    require => Package['apache2'],
  }

  file { "${webroot}/releases":
    ensure  => directory,
    mode    => '0755',
    owner   => 'deployer',
    group   => 'deployer',
    require => File[$webroot],
  }

  file { "${webroot}/storage":
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File[$webroot],
  }

  file { "${webroot}/storage/app":
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File["${webroot}/storage"],
  }

  file { "${webroot}/storage/debugbar":
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File["${webroot}/storage"],
  }

  file { "${webroot}/storage/framework":
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File["${webroot}/storage"],
  }

  file { "${webroot}/storage/framework/cache":
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File["${webroot}/storage/framework"],
  }

  file { "${webroot}/storage/framework/sessions":
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File["${webroot}/storage/framework"],
  }

  file { "${webroot}/storage/framework/views":
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File["${webroot}/storage/framework"],
  }

  file { "${webroot}/storage/logs":
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File["${webroot}/storage"],
  }

  file { "${webroot}/cache":
    ensure  => directory,
    mode    => '0775',
    owner   => 'deployer',
    group   => 'www-data',
    require => File[$webroot],
  }
  if ($dhid != {} and $db != {}) {
    file { 'env':
      ensure  => 'file',
      path    => "${webroot}/.env",
      owner   => 'deployer',
      group   => 'www-data',
      mode    => '0740', # Use 0700 if it is sensitive
      content => template('request/env.erb'),
      require => File[$webroot],
    }
  }
  exec { 'a2enmod_rewrite':
    command => '/usr/sbin/a2enmod rewrite',
    creates => '/etc/apache2/mods-enabled/rewrite.load',
    require => Package['apache2'],
    notify  => Service['apache2'],
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
    notify => Service['apache2'],
  }

  file { '/etc/ssl/private/server.key':
    ensure => file,
    owner  => 'root',
    group  => 'ssl-cert',
    mode   => '0640',
    source => 'puppet:///letsencrypt/privkey.pem',
    links  => 'follow',
    notify => Service['apache2'],
  }

  file_line { 'allow ImageMagick to work on pdf':
    path  => '/etc/ImageMagick-6/policy.xml',
    line  => '<!-- <policy domain="coder" rights="none" pattern="PDF" /> -->',
    match => '<policy domain="coder" rights="none" pattern="PDF" />',
  }

}
