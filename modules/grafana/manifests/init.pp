# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: grafana
#
# Grafana dashboards
#
# Installing Grafana via APT, see http://docs.grafana.org/installation/debian/
# for package details such as default paths etc.
#

class grafana($current_event) {

  # Adding the apt repository
  package { 'apt-transport-https':
      ensure => installed,
  }
  package { 'gnupg':
      ensure => installed,
  }
  file { 'grafana-source-add':
    ensure  => file,
    path    => '/etc/apt/sources.list.d/grafana.list',
    content => 'deb https://packages.grafana.com/oss/deb stable main',
    notify  => Exec['grafana-source-key'],
  }
  exec { 'grafana-source-key':
    command     => '/usr/bin/curl https://packages.grafana.com/gpg.key | sudo apt-key add -',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => Exec['grafana-source-update'],
  }
  exec { 'grafana-source-update':
    command     => '/usr/bin/apt-get update',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
  }

  # Installing the package
  package { 'grafana':
    ensure  => installed,
    require => [
      File['grafana-source-add'],
      Exec['grafana-source-key'],
      Exec['grafana-source-update'],
    ],
  }

  # Installing plugins
  [
    'grafana-piechart-panel',
    'gapit-htmlgraphics-panel',
  ].each |$plugin| {
    exec { "plugin-${plugin}":
      command => "/usr/sbin/grafana-cli plugins install ${plugin}",
      creates => "/var/lib/grafana/plugins/${plugin}",
    }
  }

  # LDAP integration config file
  file { 'ldap.toml':
    path    => '/etc/grafana/ldap.toml',
    content => template('grafana/ldap.toml.erb'),
    mode    => '0644',
    require => Package['grafana'],
    notify  => Service['grafana-server'],
  }

  # Our custom config
  # Note: It's a good idea to check if Grafana have added something new
  # in their default config that is enabled/not commented and missing in
  # our custom config.
  file { 'grafana-config':
    path    => '/etc/grafana/grafana.ini',
    content => template('grafana/grafana-config.ini.erb'),
    mode    => '0644',
    require => Package['grafana'],
    notify  => Service['grafana-server'],
  }

  # Making sure the server is enabled and running
  service { 'grafana-server':
    ensure  => 'running',
    enable  => true,
    require => Package['grafana'],
  }

  $password_exists = vault('grafana:login')
  if $password_exists == {} {
    # password does not exist in vault, create it and then reset grafana admin password
    exec { 'create_service_account_grafana_login':
      command => '/usr/local/bin/dh-create-service-account --type grafana --product login --username admin',
      notify  => Exec['read_password_and_reset_grafana_password'],
    }

    exec { 'read_password_and_reset_grafana_password':
      command     => [
        '/usr/local/bin/dh-create-service-account --type grafana',
        "--product login --format '{password}'",
        '| grafana-cli admin reset-admin-password --password-from-stdin',
      ].join(' '),
      refreshonly => true,
    }
  }

  # Setting up the Apache proxy
  apache::proxy { 'grafana-backend':
    url     => '/',
    backend => 'http://localhost:3001/',
  }
}
