# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: grafana
#
# Grafana dashboard for Prometheus
#
# Installing Grafana via APT, see http://docs.grafana.org/installation/debian/
# for package details such as default paths etc.
#

class dhmon::grafana($current_event) {

  # This module is written for Debian (as we'll use APT)
  if $::operatingsystem == 'Debian' {

    # Adding the apt repository
    package { 'apt-transport-https':
        ensure => installed,
    }
    file { 'grafana-source-add':
      ensure  => file,
      path    => '/etc/apt/sources.list.d/grafana.list',
      content => 'deb https://packagecloud.io/grafana/stable/debian/ stretch main',
      notify  => Exec['grafana-source-key'],
    }
    exec { 'grafana-source-key':
      command     => '/usr/bin/curl https://packagecloud.io/gpg.key | sudo apt-key add -',
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

    # LDAP integration config file
    file { 'ldap.toml':
      path    => '/etc/grafana/ldap.toml',
      content => template('dhmon/ldap.toml.erb'),
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
      content => template('dhmon/grafana-config.ini.erb'),
      mode    => '0644',
      require => Package['grafana'],
      notify  => Service['grafana-server'],
    }
    file { 'grafana-datasources':
      path    => '/etc/grafana/provisioning/datasources/datasources.yaml',
      content => template('dhmon/grafana-datasources.yaml.erb'),
      mode    => '0644',
      require => Package['grafana'],
      notify  => Service['grafana-server'],
    }
    file { 'grafana-dashboard-providers':
      path    => '/etc/grafana/provisioning/dashboards/providers.yaml',
      content => template('dhmon/grafana-providers.yaml.erb'),
      mode    => '0644',
      require => Package['grafana'],
      notify  => Service['grafana-server'],
    }
    file { '/var/lib/grafana/dashboards':
      ensure => 'directory',
    }
    file { '/var/lib/grafana/dashboards/overview.json':
      ensure => file,
      source => 'puppet:///scripts/grafana/overview.json',
      mode   => '0444',
      path   => '/var/lib/grafana/dashboards/overview.json',
    }
    file { '/var/lib/grafana/dashboards/elmia-dist.json':
      ensure => file,
      source => 'puppet:///scripts/grafana/elmia-dist.json',
      mode   => '0444',
      path   => '/var/lib/grafana/dashboards/elmia-dist.json',
    }
    file { '/var/lib/grafana/dashboards/server.json':
      ensure => file,
      source => 'puppet:///scripts/grafana/server.json',
      mode   => '0444',
      path   => '/var/lib/grafana/dashboards/server.json',
    }
    file { '/var/lib/grafana/dashboards/switch-details.json':
      ensure => file,
      source => 'puppet:///scripts/grafana/switch-details.json',
      mode   => '0444',
      path   => '/var/lib/grafana/dashboards/switch-details.json',
    }
    file { '/var/lib/grafana/dashboards/phones.json':
      ensure => file,
      source => 'puppet:///scripts/grafana/phones.json',
      mode   => '0444',
      path   => '/var/lib/grafana/dashboards/phones.json',
    }

    # Making sure the server is enabled and running
    service { 'grafana-server':
      ensure  => 'running',
      enable  => true,
      require => Package['grafana'],
    }

    # Setting up the Apache proxy
    apache::proxy { 'grafana-backend':
      url     => '/grafana',
      backend => 'http://localhost:3001',
    }
  }
}
