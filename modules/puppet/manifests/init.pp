# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: puppet
#
# Puppet agent configuration.
#
# === Parameters
#
# [*master*]
#   Puppet master to use.
#
# [*environment*]
#   Which environment to default to.
#
# [*sourceaddress*]
#   Source IP address the Puppet Agent should be using.
#

class puppet ($master, $environment, $sourceaddress) {

  service { 'puppet':
    ensure => 'running',
    name   => 'puppet',
    enable => true,
  }

  if $operatingsystem == 'Debian' and $lsbmajdistrelease == 'testing' {
    file { 'puppet-conf':
      ensure  => file,
      path    => '/etc/puppet/puppet.conf',
      content => template('puppet/puppet.conf.erb'),
    }
    package { 'puppet':
      ensure  => installed,
    }
    package { 'puppet-agent':
      ensure  => absent,
    }
    file { 'puppetlabs-pc1.list':
      ensure => absent,
      path   => '/etc/apt/sources.list.d/puppetlabs-pc1.list'
    }
  }
  if $operatingsystem == 'Debian' and $operatingsystemmajrelease == '8' {
    file { 'bashrc':
      ensure  => file,
      path    => '/root/.bashrc',
      content => template('puppet/bashrc.erb'),
      mode    => '0644',
    }
  }
}
