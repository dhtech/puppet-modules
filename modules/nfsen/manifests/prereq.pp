# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
class nfsen::prereq {

    if $operatingsystem == 'Debian' {

        exec {'mkdir':
            command => '/bin/mkdir -p /opt/nfsen/etc',
            creates => '/opt/nfsen/etc',
        }

        $reqs = ['perl', 'libapache2-mod-php5', 'php5-common', 'rrdtool', 'libmailtools-perl', 'librrds-perl', 'libio-socket-ssl-perl', 'libsocket6-perl']

        package { 'librrd4':
            ensure => present,
        }
        -> package { $reqs:
            ensure => 'installed',
        }

        # Installing nfdump from deb
        file {'/opt/nfdump-sflow_1.6.6-1_amd64.deb':
            ensure => present,
            source => 'puppet:///data/nfdump-sflow_1.6.6-1_amd64.deb',
        }
        -> package { 'nfdump-sflow':
            ensure   => latest,
            provider => dpkg,
            source   => '/opt/nfdump-sflow_1.6.6-1_amd64.deb',
            require  => Package['librrd4'],
        }
        file {'/opt/nfdump_1.6.6-1_amd64.deb':
            ensure => present,
            source => 'puppet:///data/nfdump_1.6.6-1_amd64.deb',
        }
        -> package { 'nfdump':
            ensure   => latest,
            provider => dpkg,
            source   => '/opt/nfdump_1.6.6-1_amd64.deb',
            require  => Package['librrd4'],
        }

        # nfsen www files
        file {'/opt/nfsen-1.3.6p1.tar.gz':
            ensure => present,
            source => 'puppet:///data/nfsen-1.3.6p1.tar.gz',
        }
        -> exec {'tar-nfsen':
            command => '/bin/tar xvzf /opt/nfsen-1.3.6p1.tar.gz -C /var/www/html',
            creates => '/var/www/html/nfsen-1.3.6p1',
        }
        -> exec {'move-nfsen':
            command => '/bin/mv /var/www/html/nfsen-1.3.6p1 /var/www/html/nfsen; /bin/touch /var/www/html/nfsen-1.3.6p1',
            creates => '/var/www/html/nfsen',
            require => Exec['tar-nfsen'],
        }
        -> exec { 'nfsen-wwwfiles':
            command => '/bin/ln -s /var/www/html/nfsen/nfsen.php /var/www/html/nfsen/index.php; /bin/chown -R www-data:www-data /opt/nfsen; /bin/chown -R www-data:www-data /var/www/html/nfsen',
            creates => '/var/www/html/nfsen/index.php',
        }
        file { 'nfsen-index':
            path    => '/var/www/html/index.html',
            content => template('nfsen/index.html.erb'),
        }

        # creating a service named nfsen, and enabling it
        file { 'nfsen-init':
            path    => '/etc/init.d/nfsen',
            content => template('nfsen/init.erb'),
            mode    => '0755',
        }
    }
}
nf
