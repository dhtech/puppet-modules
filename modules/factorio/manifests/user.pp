# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
class factorio::user {
    user { 'factorio':
        ensure  => present,
        comment => '',
        home    => '/home/factorio',
    }
    file { '/home/factorio':
        ensure => 'directory',
        owner  => 'factorio',
        group  => 'factorio',
        }
}