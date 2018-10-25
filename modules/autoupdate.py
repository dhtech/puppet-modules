# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file
import lib


def generate(host, *args):
    my_domain = lib.get_domain(host)

    # Only run auto updates on non-event servers
    if my_domain == 'EVENT':
        return {}

    # If an an arg begins with -, it's a package blacklist
    blacklist = [x[1:] for x in args if x[0] == '-']

    # TODO(bluecmd): be smarter which email to use
    email = 'services-colo@tech.dreamhack.se'

    info = {}
    info['blacklist'] = blacklist
    info['email'] = email

    return {'autoupdate': info}
