# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#

# == Class: hardware
#
# Install hardware specific packages and configs.
#
# === Parameters
#
# None. Everything is driven by facts.
#
class hardware {

  include apt

  if defined('$::productname') and $::productname =~ /VMware/ {
    # OpenBSD does not use open-vm-tools, see the vmt(4) driver.
    if $facts['operatingsystem'] != 'OpenBSD' {
      package { 'open-vm-tools':
        ensure => installed
      }
    }
  } else {
    if $facts['manufacturer'] == 'HP' {
      package { 'gnupg':
        ensure => installed
      }
      -> apt::key { '57446EFDE098E5C934B69C7DC208ADDE26C2B797':
        ensure => present,
        server => 'https://downloads.linux.hpe.com',
        source => 'https://downloads.linux.hpe.com/SDR/hpePublicKey2048_key1.pub',
      }
      # Use this crap since puppetlabs-apt seems to be broken with future parser
      # and 2.0.1 (Operator '[]' is not applicable to an Undef Value)
      # (::apt::config_files seems to be unset)
      -> file { 'hp-source':
        ensure  => file,
        path    => '/etc/apt/sources.list.d/hp.list',
        content => 'deb http://downloads.linux.hpe.com/SDR/repo/mcp/debian jessie/current non-free',
        notify  => Exec['apt_update'],
      }
      ~> exec { 'apt_update':
        command     => '/usr/bin/apt-get update',
        logoutput   => 'on_failure',
        try_sleep   => 1,
        refreshonly => true,
      }

      package { 'ssacli':
        ensure  => installed,
        require => [
          File['hp-source'],
          Exec['apt_update'],
        ],
      }
      -> package { 'hponcfg':
        ensure => installed
      }
      -> package { 'hp-health':
        ensure => installed
      }

    } elsif $facts['productname'] == 'Wedge-DC-F 20-001331' {
      if $facts['kernelrelease'] =~ /OpenNetworkLinux/ {
        service { 'onlpd':
          ensure => 'stopped',
          enable => false,
        }
        service { 'onlp-snmpd':
          ensure => 'stopped',
          enable => false,
        }
      }
    }
    package { 'ladvd':
      ensure => installed
    }
  }

}
