# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
#
# Class: factorio
# ===========================
#
# Full description of class factorio here.
#
class factorio ($admins = [], $password, $world_name) {

  include factorio::user
  include factorio::install
  include factorio::service

}
