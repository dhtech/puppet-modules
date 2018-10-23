# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: ldaplogin
#
# Enable system login using LDAP.
#
# === Parameters
#
# [*ca*]
#   SSH CA to trust for user authentication.
#
# [*login*]
#   Groups that are allowed to logon, in the format [group, location]
#
# [*sudo*]
#   Groups that are allowed to use sudo
#
# [*ldap*]
#   LDAP settings:
#     mount: where to mount (usually /ldap)
#     base: base DN for ldap
#     servers: ldap server DNS names
#     servers_ip: {dns: (ipv4, ipv6) tuple for the server DNS name}
#
# [*ssh_ports*]
#   What ports to listen on for ssh connections
#
# [*panic_users*]
#   Users allowed to act as the panic user 'dhtech'
#
# [*use_otp*]
#   Allow the usage of OTPs (default false)
#
# [*gitshell*]
#   Match pattern of users to put in git-shell (default '' = not active)
#
# [*host_cert*]
#   Host certificate if present (default '' = not active)

class ldaplogin ($ca, $logon, $sudo, $ldap, $ssh_ports, $panic_users,
                 $use_otp = false, $gitshell = '', $host_cert = '') {

  service { 'sssd':
    name => 'sssd',
    ensure => 'running',
    enable => true,
    require => Package['sssd'],
  }

  service { 'openssh-server':
    name => 'ssh',
    ensure => 'running',
    enable => true,
  }

  if $use_otp {
    package { 'libpam-google-authenticator':
      ensure => installed,
    }
  }

  # TODO(bluecmd): host only supports one family:
  # https://projects.puppetlabs.com/issues/8940
  each($ldap['servers']) |$srv| {
    host { "ldap-host-v4-${srv}":
     name => $srv,
     ip   => $ldap['servers_ip'][$srv][0],
    }
  }

  ensure_packages([
    'sudo',
    'sssd-tools',
    'libpam-sss',
    'libnss-sss'])

  package { 'nscd':
    ensure => purged,
  }

  file { 'access.conf':
    path    => '/etc/security/access.conf',
    ensure  => file,
    content => template('ldaplogin/access.conf.erb'),
  }

  file { 'sssd.conf':
    path    => '/etc/sssd/sssd.conf',
    ensure  => file,
    content => template('ldaplogin/sssd.conf.erb'),
    notify  => Service['sssd'],
    require => Package['sssd'],
    mode    => '0600',
  }

  file { 'ldap.conf':
    path    => '/etc/ldap/ldap.conf',
    ensure  => file,
    content => template('ldaplogin/ldap.conf.erb'),
  }

  file { 'dreamhack.issue':
    path    => '/etc/dreamhack',
    ensure  => file,
    content => template('ldaplogin/issue.erb'),
  }

  file { 'motd':
    path    => '/etc/motd',
    ensure  => file,
    content => '',
  }

  file { 'motd.tail':
    path    => '/etc/motd.tail',
    ensure  => file,
    content => '',
  }

  file { 'sshd_config':
    path    => '/etc/ssh/sshd_config',
    ensure  => file,
    content => template('ldaplogin/sshd_config.erb'),
    notify  => Service['openssh-server'],
  }

  file { 'ssh_known_hosts':
    path    => '/etc/ssh/ssh_known_hosts',
    ensure  => file,
    content => template('ldaplogin/ssh_known_hosts.erb'),
  }

  if $host_cert != '' {
    file { 'ssh_host_ecdsa_key.crt':
      path    => '/etc/ssh/ssh_host_ecdsa_key.crt',
      ensure  => 'present',
      content => "$host_cert",
      mode    => '0644',
      notify  => Service['openssh-server'],
    }
  }

  file { 'ssh_ca.pub':
    path    => '/etc/ssh/ssh_ca.pub',
    ensure  => 'present',
    content => "$ca",
    mode    => '0644',
  }

  file { 'common-account':
    path    => '/etc/pam.d/common-account',
    ensure  => file,
    content => template('ldaplogin/common-account.erb'),
    require => Package['libpam-sss'],
  }

  file { 'common-session':
    path    => '/etc/pam.d/common-session',
    ensure  => file,
    content => template('ldaplogin/common-session.erb'),
    require => Package['libpam-sss'],
  }

  file { 'common-auth':
    path    => '/etc/pam.d/common-auth',
    ensure  => file,
    content => template('ldaplogin/common-auth.erb'),
    require => Package['libpam-sss'],
  }

  file { 'pam-sshd':
    path    => '/etc/pam.d/sshd',
    ensure  => file,
    content => template('ldaplogin/sshd.erb'),
  }

  file { 'sudoers':
    path    => '/etc/sudoers.d/dreamhack',
    ensure  => file,
    mode    => '0440',
    content => template('ldaplogin/sudoers.erb'),
    require  => Package['sudo'],
  }

  file { 'dh-principals':
    path    => '/sbin/dh-principals',
    ensure  => file,
    mode    => '0755',
    source  => 'puppet:///modules/ldaplogin/dh-principals.sh',
  }

  file { 'panic-users':
    path    => '/etc/panic.users',
    ensure  => file,
    content => template('ldaplogin/panic.users.erb'),
  }

  user { 'dhtech-user':
    name           => 'dhtech',
    forcelocal     => yes,
    home           => '/home/dhtech',
    password       => '*',
    purge_ssh_keys => true,
    shell          => '/bin/bash',
  }->
  file { '/home/dhtech':
    ensure => 'directory',
    owner  => 'dhtech',
    group  => 'dhtech',
    mode   => '0700',
  }->
  file { '/home/dhtech/.bash_aliases':
    ensure  => file,
    content => template('ldaplogin/panic.bash_aliases.erb'),
  }

  if $operatingsystem == 'Debian' and $operatingsystemmajrelease == '8' {
    # SSSD in Debian 8 is not able to read our sshPublicKeys for some reason
    # so we take it from testing. openssh-server doesn't work with *that*
    # sssd version, so we take that one from testing also.
    exec { '/usr/bin/apt-get -y -t testing install openssh-server sssd libc6-dev > /var/tmp/new-ssh':
      creates => '/var/tmp/new-ssh',
    }->
    package { 'sssd':
        ensure => installed,
    }
  } elsif $operatingsystem == 'Debian' and $operatingsystemmajrelease == '7' {
    ensure_packages([
      'python-fuse',
      'python-yaml',
      'python-ldap'])

    file { 'ldapfuse.py':
      path    => '/usr/bin/ldapfuse.py',
      ensure  => file,
      mode    => '0755',
      source  => 'puppet:///scripts/ldapfuse/ldapfuse.py',
      require => [Package['python-ldap'], Package['python-yaml']],
    }

    file { 'ldap-mount-point':
      path    => $ldap['mount'],
      ensure  => directory,
    }

    mount { 'ldapfuse':
      ensure   => mounted,
      name     => $ldap['mount'],
      device   => "ldapfuse.py#ldaps://${ldap['server']}/${ldap['base']}",
      fstype   => 'fuse',
      remounts => 'false',
      options  => 'noauto,allow_other',
      require  => [File['ldap-mount-point'], File['ldapfuse.py']],
    }

    $escaped_mount = regsubst($ldap['mount'], '\/', '\\/', 'G')
    exec { 'boot-ldap':
      command => "/bin/sed -i 's/^exit 0/mount ${escaped_mount}\\nexit 0/' /etc/rc.local",
      unless => "/bin/grep -q 'mount ${ldap['mount']}' /etc/rc.local",
    }
  } elsif $operatingsystem == 'Debian' or $operatingsystem == 'Ubuntu' {
    package {
      'sssd':
        ensure => installed,
    }
  }
}
