# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
class nfsen::install {

    if $::operatingsystem == 'Debian' {

        # The nfsen config file, needs to be in place before running install script
        file { 'nfsen.conf':
            path    => '/opt/nfsen/etc/nfsen.conf',
            content => template('nfsen/nfsen.conf.erb'),
        }
        # Running nfsen install.pl script
        -> exec { 'install-nfsen':
            command => '/usr/bin/touch /opt/nfsen/.installed; /usr/bin/yes "" | ./install.pl /opt/nfsen/etc/nfsen.conf',
            cwd     => '/var/www/html/nfsen',
            creates => '/opt/nfsen/.installed',
            require => Exec['move-nfsen'],
            before  => Service['nfsen'],
        }

        service { 'nfsen':
            ensure => running,
            enable => true,
        }

        # Run nfsen reconfig if config file changes
        exec { 'nfsen-reconf':
            command     => '/usr/bin/yes | /usr/sbin/service nfsen reconfig',
            subscribe   => File['/opt/nfsen/etc/nfsen.conf'],
            refreshonly => true,
        }
    }
}
