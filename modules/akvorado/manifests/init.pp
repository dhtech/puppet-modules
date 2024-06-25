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

class akvorado ($current_event, $ipv4_prefixes, $ipv6_prefixes, $snmpv3_providers, $snmpv2_providers) {


  ##Kafka installation  
  ensure_packages([
    'openjdk-17-jre',
  ])
  group { 'kafka':
    ensure => 'present',
  }
  -> user { 'kafka':
    ensure     => 'present',
    system     => true,
    home       => '/var/lib/kafka',
    managehome => true,
  }
  -> file { '/var/lib/kafka/kafka.tgz':
    ensure => file,
    links  => follow,
    source => 'puppet:///data/kafka-latest.tgz',
    notify => Exec['untar-kafka']
  }
  -> file { '/var/log/kafka':
    ensure => 'directory',
    owner  => 'kafka',
    group  => 'kafka',
    mode   => '0700',
  }
  -> file { '/var/lib/zookeeper-data':
    ensure => 'directory',
    owner  => 'kafka',
    group  => 'kafka',
    mode   => '0700',
  }
  exec { 'untar-kafka':
    command     => '/bin/tar -xvf /var/lib/kafka/kafka.tgz -C /var/lib/kafka --strip 1',
    refreshonly => true,
    user        => 'kafka',
  }
  file { '/etc/systemd/system/kafka.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/kafka.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [ Exec['systemctl-daemon-reload'], Service['kafka'] ],
  }
  -> file { '/etc/systemd/system/zookeeper.service':
    ensure => present,
    source => 'puppet:///modules/akvorado/zookeeper.service',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
    notify => [ Exec['systemctl-daemon-reload'], Service['zookeeper'] ],
  }
  -> file_line { 'kafka-enabledeletetopics':
    ensure => 'present',
    path   => '/var/lib/kafka/config/server.properties',
    line   => 'delete.topic.enable = true',
    notify => Service['kafka'],
  }
  -> file_line { 'kafka-listenlocalhost':
    ensure => 'present',
    path   => '/var/lib/kafka/config/server.properties',
    line   => 'listeners=PLAINTEXT://localhost:9092',
    match  => '#listeners=PLAINTEXT',
    notify => Service['kafka'],
  }
  -> file_line { 'kafka-logdir':
    ensure => 'present',
    path   => '/var/lib/kafka/config/server.properties',
    line   => 'log.dirs=/var/log/kafka',
    match  => 'log.dirs=/tmp/kafka-logs',
    notify => Service['kafka'],
  }
  -> file_line { 'zookeeper-datadir':
    ensure => 'present',
    path   => '/var/lib/kafka/config/zookeeper.properties',
    line   => 'dataDir=/var/lib/zookeeper-data',
    match  => 'dataDir=/tmp/zookeeper',
    notify => Service['zookeeper'],
  }
  -> file_line { 'zookeeper-listen':
    ensure => 'present',
    path   => '/var/lib/kafka/config/zookeeper.properties',
    line   => 'clientPortAddress=127.0.0.1',
    notify => Service['zookeeper'],
  }
  service { 'kafka':
    ensure => running,
    enable => true,
  }
  service { 'zookeeper':
    ensure => running,
    enable => true,
  }

  ##Clickhouse installation
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
  exec { 'clickhouse-source-key':
    command     => '/usr/bin/curl -fsSL https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key | gpg --dearmor > /usr/share/keyrings/clickhouse-keyring.gpg',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    notify      => Exec['apt-update'],
  }
  exec { 'apt-update':
    command     => '/usr/bin/apt-get update',
    logoutput   => 'on_failure',
    try_sleep   => 1,
    refreshonly => true,
    require     => Package['apt-transport-https'],
  }

  package { 'clickhouse-server':
    ensure  => installed,
    require => [File['clickhouse-source-add'], Exec['clickhouse-source-key'], Exec['apt-update']],
  }
  -> package { 'clickhouse-client':
    ensure => installed,
  }
  -> service { 'clickhouse-server':
    ensure => running,
    enable => true,
  }

  #Create user/group for Akvorodo
  ensure_packages([
    'redis',
  ],{
    ensure => 'present',
    notify => Service['redis'],
  })
  group { 'akvorado':
    ensure => 'present',
      }
  -> user { 'akvorado':
    ensure => 'present',
    system => true,
    home       => '/var/lib/akvorado',
    managehome => true,
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
    notify => [Service['akvorado-orch'],Exec['protobuf-schema']]
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
  file { '/usr/share/GeoIP':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { '/usr/share/GeoIP/asn.mmdb':
    ensure => present,
    source => 'puppet:///data/asn.mmdb',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }
  file { '/usr/share/GeoIP/country.mmdb':
    ensure => present,
    source => 'puppet:///data/country.mmdb',
    mode   => '0644',
    owner  => 'root',
    group  => 'root',
  }
  apache::proxy { '1_akvorado-orch-api':
    url     => '/api/v0/orchestrator/',
    backend => 'http://localhost:8080/api/v0/orchestrator/',
  }
  apache::proxy { '2_akvorado-inlet-api':
    url     => '/api/v0/inlet/',
    backend => 'http://localhost:8081/api/v0/inlet/',
  }
  apache::proxy { '3_akvorado-console':
    url     => '/',
    backend => 'http://localhost:8082/',
  }
  # By default apache answers with status code 404 when an URL contains an encoded slash (%2F) 
  # The following allows apache to simply forward the request to the prox backend.
  file { '/etc/apache2/conf-available/allow-slashes.conf':
    content => 'AllowEncodedSlashes On',
    ensure  => present,
    mode    => '0644',
  }
  -> file { '/etc/apache2/conf-enabled/allow-slashes.conf':
    ensure => link,
    mode   => '0644',
    target => '/etc/apache2/conf-available/allow-slashes.conf',
  }
  service { 'akvorado-orch':
    ensure => running,
    enable => true,
  }
  service { 'akvorado-inlet':
    ensure => running,
    enable => true,
  }
  service { 'akvorado-console':
    ensure => running,
    enable => true,
  }
  service { 'redis':
    ensure => running,
    enable => true,
  }
  exec { 'systemctl-daemon-reload':
    command     => '/bin/systemctl daemon-reload',
    refreshonly => true,
  }
  exec { 'protobuf-schema':
    command     => '/usr/bin/curl http://127.0.0.1:8080/api/v0/orchestrator/clickhouse/init.sh | sh',
    refreshonly => true,
    require     => Service['akvorado-orch']
  }
}
