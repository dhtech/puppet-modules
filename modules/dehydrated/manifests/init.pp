# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: dehyfrated
#
# Installs dehydrated letsencrypt client and generates certificates.
#
# === Parameters
#
# Document parameters here.
#
# [*hostname_list*]
#   List of hostnames to generate certificates for in additionto fqdn.
#

class dehydrated($hostname_list = []) {
	#TODO(reth): handle hostname_list

	exec { "clone dehydrated git repo":
		command		=> "/usr/bin/git clone https://github.com/lukas2511/dehydrated.git /opt/dehydrated",
		creates		=> "/opt/dehydrated",
		timeout		=> 600,
	}

	file { '/var/www/dehydrated':
		ensure		=> directory,
	}

	file { '/etc/dehydrated':
		ensure		=> directory,
	}

	file { '/etc/dehydrated/domains.txt':
		require		=> File['/etc/dehydrated'],
		mode		=> '0755',
		content		=> template('dehydrated/domains.txt.erb'),
	}

	file { '/etc/apache2/conf-enabled/dehydrated.conf':
		require		=> Package['apache2'],
		mode		=> '0755',
		content		=> template('dehydrated/dehydrated-apache.conf.erb'),
		notify		=> Service['apache2'],
	}

	file { '/etc/dehydrated/config':
		require		=> File['/etc/dehydrated'],
		mode		=> '0755',
		content		=> template('dehydrated/config.erb'),
	}
	file { 'dehydrated-update':
		path		=> '/usr/local/bin/dehydrated-update',
		ensure		=> file,
		mode		=> '0755',
		content		=> template('dehydrated/dehydrated-update.erb'),
	}

	cron { 'updatecerts':
		command		=> '/usr/local/bin/dehydrated-update',
		user		=> 'root',
		hour		=> '2',
		minute		=> '10',
		require		=> File['dehydrated-update'],
	}

	exec { 'dehydrated-update':
		command		=> '/usr/local/bin/dehydrated-update',
		require		=> File['/var/www/dehydrated',
					'/etc/dehydrated/config',
					'/etc/dehydrated/domains.txt'],
		refreshonly	=> true,
	}


}
