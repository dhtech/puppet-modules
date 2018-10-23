# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: rabbitmq
#
# RabbitMQ server with Vault credentials
#
# === Parameters
#

class rabbitmq {
  ensure_packages(['rabbitmq-server'])

  $mq_username = 'dhtech'
  $mq_password = vault("rabbitmq:${fqdn}")

  service { 'rabbitmq-server':
    ensure => running,
    require => Package['rabbitmq-server'],
  }

  exec { 'enable-rabbitmq-admin':
    command => '/usr/sbin/rabbitmq-plugins enable rabbitmq_management',
    environment => 'HOME=/var/lib/rabbitmq',
    creates => '/etc/rabbitmq/enabled_plugins',
    notify  => Service['rabbitmq-server'],
  }

  if $mq_password == {} {
    file { 'setup_rabbitmq.sh':
      path    => '/tmp/setup_rabbitmq.sh',
      content => template('rabbitmq/setup_rabbitmq.sh.erb'),
      mode    => '0500',
    }->
    exec { 'setup-rabbitmq':
      command => "/tmp/setup_rabbitmq.sh ${mq_username}",
      notify  => Service['rabbitmq-server'],
      require => Package['rabbitmq-server'],
    }
  }
}
