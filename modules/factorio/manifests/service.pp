# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
class factorio::service {
    service { 'factorio_service':
        ensure  => true,
        name    => 'factorio',
        enable  => true,
        }
}
