# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: mysql
#
# Installs and configures the MySQL database.
#
# The root password is auto-generated and stored in /root/.
#
# A script for creating databases (and their users) is installed in /root/.
#
# === Parameters
#
# None.

class mysql {
  package {
    'mysql-server':
      ensure => present,
  }

  service {
    'mysql':
      ensure  => running,
      enable  => true,
      require => Package['mysql-server'],
  }

  file_line {
    'listen-all-interfaces':
      path   => '/etc/mysql/my.cnf',
      line   => 'bind-address = 0.0.0.0',
      match  => '^bind-address',
      notify => Service['mysql'],
  }

  exec {
    'generate and store mysql root password':
      command  => "(tr -dc 'A-Za-z0-9' | fold -w 20 | head -n1) < /dev/urandom >
                  /root/mysql_root_password.txt; chmod 600 /root/mysql_root_password.txt;
                  mysql -u root -e \"UPDATE mysql.user SET password=PASSWORD('`cat
                  /root/mysql_root_password.txt`') WHERE user='root'; FLUSH PRIVILEGES;\"",
      creates  => '/root/mysql_root_password.txt',
      require  => Service['mysql'],
      provider => 'shell',
  }

  file {
    '/root/create_db_with_user.sh':
      source => 'puppet:///modules/mysql/create_db_with_user.sh'
  }
}
