# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: akvorado
#
# Alert manager for prometheus to handle sending alerts
#
# === Parameters
#

class akvorado {

  #Create user/group for Akvorodo
  group { 'akvorado':
    ensure => 'present',
      }
  -> user { 'akvorado':
    ensure => 'present',
    system => true,
  }
  #Create directories for akvorado
  -> file { '/etc/akvorado':
    ensure => 'directory',
    owner  => 'root',
    group  => 'akvorado',
    mode   => '0750',
  }
  #Copy akvorado to the server
  -> file { '/usr/local/bin/akvorado':
    ensure => file,
    owner  => 'root',
    group  => 'akvorado',
    mode   => '0550',
    links  => follow,
    source => 'puppet:///data/akvorado-latest',
  }

  file { '/etc/akvorado/akvorado.yaml':
    ensure  => file,
    content => template('akvorado/akvorado.yaml.erb'),
    notify  => Service['akvorado-orch'],
  }
  #Systemctl config
  file { '/etc/systemd/system/akvorado-orch.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/akvorado-orch.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [Exec['systemctl-daemon-reload'],Service['akvorado-orch']],
  }
  file { '/etc/systemd/system/akvorado-inlet.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/akvorado-inlet.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [Exec['systemctl-daemon-reload'],Service['akvorado-inlet']],
  }
  file { '/etc/systemd/system/akvorado-console.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/akvorado-console.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [Exec['systemctl-daemon-reload'],Service['akvorado-console']],
  }

  -> apache::proxy { 'akvorado':
    url     => '/',
    backend => 'http://localhost:8082/',
  }
  -> service { 'akvorado-orch':
    ensure  => running,
  }
-> service { 'akvorado-inlet':
    ensure  => running,
  }
-> service { 'akvorado-console':
    ensure  => running,
  }

  exec { 'systemctl-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }

  ##Kafka installation  
  group { 'kafka':
    ensure => 'present',
  }
  -> user { 'kafka':
    ensure     => 'present',
    system     => true,
    home       => '/var/lib/kafka',
    managegome => true,
  }
  -> file { '/tmp/kafka.tgz':
    ensure => file,
    links  => follow,
    source => 'puppet:///data/kafka-latest.tgz',
    notify => Exec[ 'untar-kafka' ],
  }
  -> file { '/var/log/kafka':
    ensure => 'directory',
    owner  => 'kafka',
    group  => 'kafka',
    mode   => '0700',
  }
  -> file { '/etc/systemd/system/kafka.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/kafka.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [Exec['systemctl-daemon-reload'],Service['kafka']],
  }
  -> file_line { 'kafka-enabledeletetopics'
    ensure => 'present',
    path => '/var/lib/kafka/config/server.properties',
    line => 'delete.topic.enable = true'
    line => 'delete.topic.enable'
  }
  -> file_line { 'kafka-listenlocalhost'
    ensure  => 'present',
    path    => '/var/lib/kafka/config/server.properties',
    line    => 'listeners=PLAINTEXT://localhost:9092'
    match   => '#listeners=PLAINTEXT'
  }
  -> file_line { 'kafka-logdir'
    ensure  => 'present',
    path    => '/var/lib/kafka/config/server.properties',
    line    => 'log.dirs=/var/log/kafka'
    match   => 'log.dirs='
  }
  exec { 'untar-kafka':
    command     => '/bin/tar -zxf /tmp/kafka.tgz -C /var/lib/kafka --strip=1',
    refreshonly => true,
    user        => 'kafka',
  }

  ##Zookeeper installation
  ensure_packages([
    'apt-transport-https',
    'ca-certificates',
    'curl',
    'gnupg',
  ])
  file { 'clickhouse-source-add':
    ensure  => file,
    path    => '/etc/apt/sources.list.d/clickhouse.list',
    content => 'deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg] https://packages.clickhouse.com/deb stable main',
    notify  => Exec['clickhouse-source-key'],
  }
  file_line { 'clickhouse-listen'
    ensure  => 'present',
    path    => '/var/lib/kafka/config/server.properties',
    line    => 'clientPortAddress=127.0.0.1',
    match   => 'clientPortAddress=',
  }
  exec { 'clickhouse-source-key':
    command     => '/usr/bin/wget -fsSLhttps://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key -O /usr/share/keyrings/clickhouse-keyring.gpg',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => Exec['docker-source-update'],
  }
  exec { 'apt-update':
    command     => '/usr/bin/apt-get update',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    require     => Package['apt-transport-https'],
  }

  package { 'clickhouse':
    ensure  => installed,
    require => [File['clickhouse-source-add'], Exec['clickhouse-source-key'], Exec['apt-update'], File_Line['clickhouse-listen']],
  }
  -> file { '/etc/systemd/system/clickhouse.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/clickhouse.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [Exec['systemctl-daemon-reload'],Service['clickhouse']],
  }
}
