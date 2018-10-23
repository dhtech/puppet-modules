# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: plexporter
#
#  Sets up the plexporter and the prerequisites, exports prometheus metrics
#  gathered from the procera packetlogic API
#
# === Parameters
#

class plexporter {

    $secret_login_packetlogic = vault("login:packetlogic", {})

    package { ['virtualenv', 'python-virtualenv']:
        ensure => installed,
    }
    ->
    file { '/opt/plexporter':
        ensure => directory,
    }
    ->
    exec { 'virtualenv':
        command => '/usr/bin/virtualenv -p $(which python2.7) /opt/plexporter/env',
        creates => '/opt/plexporter/env',
    }
    ->
    exec { 'install-prometheus-client':
        command => '/opt/plexporter/env/bin/pip install prometheus-client',
        unless  => '/opt/plexporter/env/bin/pip list | grep -i prometheus-client'
    }
    ->
    exec { 'install-yaml':
        command => '/opt/plexporter/env/bin/pip install pyyaml',
        unless  => '/opt/plexporter/env/bin/pip list | grep -i pyyaml'
    }

    # The packetlogic2 python API
    package { ['python2.7-dev', 'libssl-dev', 'libffi-dev']:
        ensure => installed,
    }
    ->
    file {'plapi':
        path   => '/opt/plexporter/plapi-17.2.0py1-py2.7-linux-x86_64.egg',
        ensure => present,
        source => 'puppet:///data/plapi-17.2.0py1-py2.7-linux-x86_64.egg',
    }
    ->
    exec { 'install-plapi':
        command => '/opt/plexporter/env/bin/easy_install /opt/plexporter/plapi-17.2.0py1-py2.7-linux-x86_64.egg',
        unless  => '/opt/plexporter/env/bin/pip list | grep -i plapi',
    }

    # plexporter config file
    file {'plexporter.yaml':
        path   => '/etc/plexporter.yaml',
        ensure => present,
        content => template('plexporter/plexporter.yaml.erb'),
    }
    ->
    # plexporter itself
    file {'plexporter.py':
        path   => '/opt/plexporter/plexporter.py',
        ensure => present,
        source => 'puppet:///scripts/plexporter/plexporter.py',
        mode   => '0755',
        notify => Supervisor::Restart['plexporter'],
    }
    ->
    supervisor::register { 'plexporter':
        command   => '/opt/plexporter/env/bin/python /opt/plexporter/plexporter.py'
    }
}
