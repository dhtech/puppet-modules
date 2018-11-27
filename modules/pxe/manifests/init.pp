# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: pxe
#
# Full description of class here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#

class pxe {

  include wget

  package {
    'tftpd-hpa':
      ensure => present,
  }

  package {
    'nginx':
      ensure => present,
  }

  #file {
  #  '/srv/tftp/ipxe.pxe':
  #    ensure => present,
  #    source => 'puppet:///modules/pxe/ipxe.pxe',
  #}

  #file {
  #  '/srv/tftp/ipxe.efi':
  #    ensure => present,
  #    source => 'puppet:///modules/pxe/ipxe.efi',
  #}

  #service {
  #  'tftpd-hpa':
  #    ensure => running,
  #}

  service {
    'nginx':
      ensure => running,
  }

  #file {
  #  '/srv/www/':
  #    ensure  => directory,
  #    recurse => true,
  #    source  => 'puppet:///modules/pxe/www',
  #}

  #file {
  #  '/etc/nginx/sites-enabled/pxe':
  #    ensure => file,
  #    source => 'puppet:///modules/pxe/nginx-pxe',
  #    notify => Service['nginx'],
  #}

  #file {
  #  '/etc/nginx/sites-enabled/default':
  #    ensure => absent,
  #    notify => Service['nginx'],
  #}

}
