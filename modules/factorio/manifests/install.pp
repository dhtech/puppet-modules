# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
class factorio::install {
    $world_name = $factorio::world_name
    $password = $factorio::password
    $admins = $factorio::admins
    $required_packages = [ 'wget', 'unzip' ]
    package { $required_packages:
        ensure => installed,
    }
    exec { 'download':
        #command => '/usr/bin/wget -O /home/factorio/server.tar.gz https://factorio.com/get-download/latest/headless/linux64',
        command => '/usr/bin/wget -O /home/factorio/server.tar.gz https://factorio.com/get-download/stable/headless/linux64',
        user => 'factorio',
        unless  => '/usr/bin/test -f /home/factorio/server.tar.gz',
        }
    exec { 'extract':
        command => '/bin/tar xvf server.tar.gz',
        cwd     => '/home/factorio',
        user => 'factorio',
        unless  => '/usr/bin/test -d /home/factorio/factorio',
        require  => [Exec['download']],
        }
    file { '/home/factorio/ensure_permissions.py':
	ensure   => file,
	owner    => 'factorio',
        group 	 => 'factorio',
	mode     => '0644',
	source	 => 'puppet:///modules/factorio/ensure_permissions.py',
	}
    exec { 'factorio_chown':
        command  => '/bin/chown -R factorio:factorio /home/factorio',
        unless   => '/usr/bin/python /home/factorio/ensure_permissions.py',
        require  => [Exec['extract'], File['/home/factorio/ensure_permissions.py']],
        }
    file { '/etc/systemd/system/factorio.service':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => template('factorio/factorio.service.erb'),
        }
    file { '/home/factorio/factorio/data/server-settings.json':
        ensure  => file,
        owner   => 'factorio',
        group   => 'factorio',
        mode    => '0640',
        content => template('factorio/server-settings.json.erb'),
	notify  => Service['factorio_service'],
        }
    exec { 'create_server':
        command => "/home/factorio/factorio/bin/x64/factorio --create /home/factorio/factorio/saves/$world_name.zip",
        unless  => "/usr/bin/test -f /home/factorio/factorio/saves/$world_name.zip",
        }
    exec { 'reload_systemd':
        command     => '/bin/systemctl daemon-reload',
        refreshonly => true,
        subscribe   => File['/etc/systemd/system/factorio.service'],
	notify      => Service['factorio_service']
        }
}
