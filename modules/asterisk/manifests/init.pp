# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: asterisk
#
# Asterisk deployment and configuration module
#
# === Parameters
#
# [*current_event*]
#   The current event, used to decide the name of the dhcpinfo database
#

class asterisk($current_event) {
	$iax_secret	= vault("asterisk:iax2", {})

	package { "asterisk":
		ensure	=> installed,
	}
	package { "python-jinja2":
		ensure	=> installed,
	}
	service { "asterisk":
		ensure 	=> running,
		require	=> Package['asterisk'],
		enable	=> true,
	}
	file { "/etc/voipplan":
		notify	=> Exec['update_configuration_files'],
		mode	=> '644',
		owner	=> 'asterisk',
		group	=> 'asterisk',
		source	=> "puppet:///svn/$current_event/services/voipplan",
	}
	file { "/etc/asterisk/iax.conf":
		ensure	=> file,
		owner	=> 'asterisk',
		group	=> 'asterisk',
		mode	=> '0644',
		content	=> template('asterisk/iax.conf.erb'),
		require	=> Package['asterisk'],
		notify	=> Exec['reload_asterisk'],
	}
	exec { "reload_asterisk":
		command 	=> "service asterisk reload",
		refreshonly 	=> true,
		path		=> "/usr/bin:/bin/:/sbin:/usr/sbin",
	}

	exec { "update_configuration_files":
		notify		=> Exec['reload_asterisk'],
		refreshonly	=> true,
		command		=> "python run.py /etc/voipplan",
		cwd		=> "/scripts/voip-parse",
		path    	=> '/usr/bin/:/bin/',
	}
}
