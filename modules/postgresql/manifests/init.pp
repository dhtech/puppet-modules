# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: postgresql
#
# Installs and configures a PostgreSQL server.
#
# === Parameters
#
# [*allowed_hosts*]
#   Hosts that are allowed to connect to the database.
#
# [*db_list*]
#   List of databases that live on the managed host.
#
# [*current_event*]
#   Used for naming databases.
#
# [*domain*]
#   Used for naming databases.
#

class postgresql($allowed_hosts, $db_list = [], $current_event, $domain) {
  package {'postgresql':
    ensure => 'installed',
  }

  service {'postgresql':
    ensure  => running,
    enable  => true,
    require => Package['postgresql'],
  }

  file_line {'listen-on-network':
    path    => '/etc/postgresql/10/main/postgresql.conf',
    line    => "listen_addresses = '*'",
    notify  => Service['postgresql'],
    require => Package['postgresql'],
  }

  file {'/etc/postgresql/10/main/pg_hba.conf':
    content => template('postgresql/pg_hba.conf.erb'),
    mode    => '0640',
    owner   => 'postgres',
    group   => 'postgres',
    notify  => Service['postgresql'],
    require => Package['postgresql'],
  }

  file { '/opt/postgresql':
    ensure => 'directory',
    mode   => '0750',
    owner  => 'postgres',
    group  => 'postgres',
  }

  file { '/opt/postgresql/bin':
    ensure  => 'directory',
    mode    => '0750',
    owner   => 'postgres',
    group   => 'postgres',
    require => File['/opt/postgresql'],
  }

  file { '/opt/postgresql/bin/psql_database_exists':
    content => template('postgresql/psql_database_exists.erb'),
    mode    => '0755',
    owner   => 'postgres',
    group   => 'postgres',
    require => File['/opt/postgresql/bin'],
  }

  file { '/opt/postgresql/bin/psql_user_exists':
    content => template('postgresql/psql_user_exists.erb'),
    mode    => '0755',
    owner   => 'postgres',
    group   => 'postgres',
    require => File['/opt/postgresql/bin'],
  }

  file { '/opt/postgresql/bin/psql_user_permissions':
    content => template('postgresql/psql_user_permissions.erb'),
    mode    => '0755',
    owner   => 'postgres',
    group   => 'postgres',
    require => File['/opt/postgresql/bin'],
  }

  file { '/opt/postgresql/bin/psql_set_user_permissions':
    content => template('postgresql/psql_set_user_permissions.erb'),
    mode    => '0755',
    owner   => 'postgres',
    group   => 'postgres',
    require => File['/opt/postgresql/bin'],
  }

  exec { 'create_user_root':
    user    => 'postgres',
    cwd     => '/var/lib/postgresql',
    command => "/bin/echo 'CREATE USER root SUPERUSER' | /usr/bin/psql",
    unless  => '/opt/postgresql/bin/psql_database_exists root',
    require => [ Package['postgresql'],
                     File['/opt/postgresql/bin/psql_user_exists'],
               ],
  }

  exec { 'create_database_root':
    user    => 'postgres',
    cwd     => '/var/lib/postgresql',
    command => '/usr/bin/createdb root',
    unless  => '/opt/postgresql/bin/psql_database_exists root',
    require => [ Exec['create_user_root'],
                 File['/opt/postgresql/bin/psql_database_exists'],
               ],
  }

  each($db_list) |$db| {
    $secret = vault("postgresql:${db}")
    $dbusername = $secret['username']

    if $domain == 'EVENT' {
      $dbname = "${db}_${current_event}"
    } else {
      $dbname = $db
    }

    file { "/opt/postgresql/${db}.sql":
      content => template("postgresql/${db}.sql.erb"),
      mode    => '0640',
      owner   => 'postgres',
      group   => 'postgres',
      require => File['/opt/postgresql'],
    }

    exec { "create_${dbname}":
      user    => 'postgres',
      cwd     => '/var/lib/postgresql',
      command => "/usr/bin/createdb ${dbname}",
      unless  => "/opt/postgresql/bin/psql_database_exists ${dbname}",
      notify  => [ Exec["initialize_${dbname}"],
                 ],
      require => [ File['/opt/postgresql/bin/psql_database_exists'],
                   Exec['create_user_root'],
                 ],
    }

    exec { "initialize_${dbname}":
      user        => 'postgres',
      cwd         => '/var/lib/postgresql',
      command     => "/usr/bin/psql ${dbname} < /opt/postgresql/${db}.sql",
      refreshonly => true,
    }

    if $secret == {} {
      exec { "create_service_account_${db}":
        command => "/usr/local/bin/dh-create-service-account --type postgresql --product ${db}",
        notify  => Exec["alter_user_${db}"],
      }
    }

    exec { "alter_user_${db}":
      command     => "/usr/local/bin/dh-create-service-account --type postgresql --product ${db} --format \"ALTER USER {username} ENCRYPTED PASSWORD '{password}'\" | /usr/bin/psql",
      onlyif      => "/opt/postgresql/bin/psql_user_exists ${db}",
      refreshonly => true,
    }

    exec { "check_user_${db}":
      user    => 'postgres',
      cwd     => '/var/lib/postgresql',
      command => '/bin/true',
      unless  => "/opt/postgresql/bin/psql_user_exists ${dbusername}",
      require => File['/opt/postgresql/bin/psql_user_exists'],
      notify  => Exec["create_user_${db}"],
    }

    exec { "create_user_${db}":
      command     => "/usr/local/bin/dh-create-service-account --type postgresql --product ${db} --format \"CREATE USER {username} ENCRYPTED PASSWORD '{password}'\" | /usr/bin/psql",
      notify      => Exec["set_permissions_for_${db}"],
      require     => [ Exec['create_database_root'],
                       Exec["create_${dbname}"],
                     ],
      refreshonly => true,
    }

    exec { "check_permissions_for_${db}":
      user    => 'postgres',
      cwd     => '/var/lib/postgresql',
      command => '/bin/true',
      unless  => "/opt/postgresql/bin/psql_user_permissions ${dbusername} ${dbname}",
      require => File['/opt/postgresql/bin/psql_user_permissions'],
      notify  => Exec["set_permissions_for_${db}"],
    }

    exec { "set_permissions_for_${db}":
      user        => 'postgres',
      cwd         => '/var/lib/postgresql',
      command     => "/opt/postgresql/bin/psql_set_user_permissions ${dbusername} ${dbname}",
      require     => [ File['/opt/postgresql/bin/psql_set_user_permissions'],
                       Exec["initialize_${dbname}"]
                     ],
      refreshonly => true,
    }
  }
}
