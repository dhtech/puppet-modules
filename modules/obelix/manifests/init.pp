# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# == Class: obelix
#
# Asterisk deployment and configuration module for colo obelix service
#

class obelix {
	package { "asterisk":	
		ensure	=> installed,
	}
	service { "asterisk":
		ensure 	=> running,
		require	=> Package['asterisk'],	
		enable	=> true,
	}
}
