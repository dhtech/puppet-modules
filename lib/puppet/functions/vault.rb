# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
require 'json'

Puppet::Functions.create_function(:'vault') do
  dispatch :vault do
    required_param 'String', :str
    optional_param 'Hash', :default
  end

  def vault(str, default = {})
    return default if (str =~ /^[a-z0-9\:\-\.]+$/).nil?

    raw = `/usr/local/bin/puppet-vault #{str}`
    return default if raw.size() == 0

    result = JSON.parse(raw)
    return result if result.size()
    return default
  end
end
