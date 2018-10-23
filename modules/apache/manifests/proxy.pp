# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
define apache::proxy($url, $backend) {
  exec { "apache_proxy_reload_${name}":
    command     => '/usr/sbin/apachectl graceful',
    refreshonly => 'true',
  }

  file { "proxy_${name}":
    path    => "/etc/apache2/site.d/$name.conf",
    ensure  => file,
    content => template('apache/proxy.conf.erb'),
    notify  => Exec["apache_proxy_reload_${name}"],
  }
}
