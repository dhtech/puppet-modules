# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: dhcpd
#
# This class manages the ISC dhcpd server.
#
# === Parameters
#
# [*active*]
#   Decides of we are the active DHCP server.
#
# [*active_node*]
#   String containing fqdn for the active DHCP server.
#
# [*scopes*]
#   The scopes that the server will handle.
#
# [*local_subnet*]
#   The subnet where the the dhcpd server lives.
#
# [*local_netmask*]
#   The netmask used by the dhcpd server.
#
# [*domain_name_servers*]
#   String for domain-name-servers option
#
# [*next_server*]
#   String for next-server option
#
# [*ntp_servers*]
#   String for ntp-servers option
#
# [*tftp_server_name*]
#   String for tftp-server-name option
#
# [*current_event*]
#   The current event, used to decide the name of the dhcpinfo database
#

class dhcpd ($current_event, $active = 0, $active_node = '', $scopes = '', $local_subnet = '',
              $local_netmask = '', $domain_name_servers = '', $next_server = '',
              $ntp_servers = '', $tftp_server_name = '')  {

  if $::operatingsystem == 'OpenBSD' {
    $conf_dir = '/etc'
    $package_name = 'isc-dhcp-server'
    $rc_name = 'isc_dhcpd'
    $create_dhcpd_leases = 1
    $dhcpd_leases_file = '/var/db/dhcpd.leases'
    $cert_dir = '/var/lib/puppet/ssl'
  }
  else {
    $conf_dir = '/etc/dhcp'
    $package_name = 'isc-dhcp-server'
    $rc_name = 'isc-dhcp-server'
    $create_dhcpd_leases = 0
    $cert_dir = '/var/lib/puppet/ssl'
  }

  if $package_name != '' {
    package { $package_name:
      ensure => installed,
    }
  }

  # The default configuration file
  file { 'default-isc-dhcp-server':
    ensure  => file,
    path    => '/etc/default/isc-dhcp-server',
    content => template('dhcpd/default-isc-dhcp-server.erb'),
    notify  => Service['dhcpd'],
  }

  # The main configuration
  file { 'dhcpd.conf':
    ensure  => file,
    path    => "${conf_dir}/dhcpd.conf",
    content => template('dhcpd/dhcpd.conf.erb'),
    notify  => Service['dhcpd'],
  }

  # The scopes generated from ipplan
  file { 'dhcpd.conf.scopes':
    ensure  => file,
    path    => "${conf_dir}/dhcpd.conf.scopes",
    content => template('dhcpd/dhcpd.conf.scopes.erb'),
    notify  => Service['dhcpd'],
  }

  # The locally managed (normally empty) fallback file
  file { 'dhcpd.conf.local':
    ensure => file,
    path   => "${conf_dir}/dhcpd.conf.local",
  }

  # Make sure a dhcpd.leases file exists if necessary.
  # If it does not exist then dhcpd gets upset:
  # dhcpd: Can't open lease database /var/db/dhcpd.leases: No such file or directory --
  if $create_dhcpd_leases == 1 {
    file { $dhcpd_leases_file:
      ensure => file,
      path   => $dhcpd_leases_file,
    }
  }

  # Install the dhcp_leased utility and dependencies. Currently only supported
  # on Debian
  if $::operatingsystem == 'Debian' {

    package { 'libpq5':
      ensure => installed,
    }

    package { 'libpqtypes0':
      ensure => installed,
    }

    package { 'libfl2':
      ensure => installed,
    }

    file { '/usr/local/sbin/dhcp_leased':
      ensure => file,
      source => "puppet:///scripts/dhcp_leased/bin/${::operatingsystem}-${facts['os']['release']['major']}-${::hardwaremodel}/dhcp_leased",
      mode   => '0755',
      path   => '/usr/local/sbin/dhcp_leased',
    }

    file { 'dhcp_populate_scopes':
      ensure => file,
      source => "puppet:///scripts/dhcp_leased/bin/${::operatingsystem}-${facts['os']['release']['major']}-${::hardwaremodel}/dhcp_populate_scopes",
      mode   => '0755',
      path   => '/usr/local/sbin/dhcp_populate_scopes',
    }

    file { '/usr/local/sbin/dhcp_leased_ready':
      ensure  => file,
      mode    => '0755',
      content => template('dhcpd/dhcp_leased_ready.erb'),
    }

    # Configure dhcp_leased.
    supervisor::register{ 'dhcp_leased':
      command   => '/usr/local/sbin/dhcp_leased /var/lib/dhcp/dhcpd.leases',
      autostart => false,
    }

    $secret = vault('postgresql:dhcpinfo')

    # TODO-eest: We have dependency chain where ddns1.event.dreamhack.se needs
    # to be available before db.event.dreamhack.se meaning we can not fill
    # in dhcp_leased.conf from the beginning. In order to not have puppet
    # fail (which breaks firewall rule application etc.) we need this extra
    # logic until we are able to install a DNS service prior to installing a
    # DHCP service.
    if $secret != {} {
      $dhcpinfo_hostname = $secret['hostname']
      $dhcpinfo_username = $secret['username']
      $dhcpinfo_password = $secret['password']

      file { '/etc/dhcp_leased.conf':
        ensure  => file,
        content => template('dhcpd/dhcp_leased.conf.erb'),
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
        path    => '/etc/dhcp_leased.conf',
      }
    }
  }

  if $active == 1 {
    service { 'isc-dhcp-server':
      ensure => 'running',
      name   => $rc_name,
      enable => true,
    }

    # NOTE: The dhcp_leased parts currently only work on Debian
    if $::operatingsystem == 'Debian' {
      exec { 'start_dhcp_leased':
        command => '/usr/bin/supervisorctl start dhcp_leased',
        onlyif  => '/usr/local/sbin/dhcp_leased_ready',
        require => [
          Supervisor::Register['dhcp_leased'],
          File['/usr/local/sbin/dhcp_leased_ready'],
          Exec['dhcp_populate_scopes'],
        ],
      }

      # TODO-eest: Ugly workaround to deal with the problem that we only run
      # dhcp_populate_scopes when the scopes file is modified, which might not occur
      # after the point where db.event.dreamhack.se is available.
      exec { 'dhcp_populate_scopes_first_time':
        command => '/usr/local/sbin/dhcp_populate_scopes /etc/dhcp/dhcpd.conf.scopes
                    && /usr/bin/touch /root/.puppet_dhcp_populate_scopes_first_time',
        require => [
          File['dhcpd.conf.scopes'],
          File['dhcp_populate_scopes'],
        ],
        creates => '/root/.puppet_dhcp_populate_scopes_first_time',
        onlyif  => '/usr/bin/test -f /etc/dhcp_leased.conf',
      }

      exec { 'dhcp_populate_scopes':
        command     => '/usr/local/sbin/dhcp_populate_scopes /etc/dhcp/dhcpd.conf.scopes',
        refreshonly => true,
        require     => [
          File['dhcpd.conf.scopes'],
          File['dhcp_populate_scopes'],
        ],
        subscribe   => File['dhcpd.conf.scopes'],
      }

      # dhcpsync hosts the dhcp lease file over HTTPS
      file { '/usr/local/sbin/dhcpsync':
        ensure => file,
        source => 'puppet:///scripts/ddns/dhcpsync',
        mode   => '0755',
        path   => '/usr/local/sbin/dhcpsync',
      }
      -> supervisor::register{ 'dhcpsync':
        command   => "/usr/local/sbin/dhcpsync -ca ${cert_dir}/certs/ca.pem
                    -cert ${cert_dir}/certs/${::fqdn}.pem -key ${cert_dir}/private_keys/${::fqdn}.pem",
        autostart => true,
      }
    }
  }
  else {
    service { 'dhcpd':
      ensure => 'stopped',
      name   => $rc_name,
      enable => false,
    }
    if $::operatingsystem == 'Debian' {
      # Install the sync-leases utility
      file { 'sync-leases':
        ensure  => file,
        content => template('dhcpd/sync-leases.erb'),
        mode    => '0755',
        path    => '/usr/local/sbin/sync-leases',
      }

      cron { 'sync-leases':
        command => '/usr/local/sbin/sync-leases',
        user    => root,
        minute  => '*/5'
      }
    }
  }

}
