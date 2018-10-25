# Copyright 2018 dhtech
#
# Use of this source code is governed by a BSD-style
# license that can be found in the LICENSE file


def generate(host, *args):

    install = set()
    purge = set()

    for pkg in args:
        if not pkg:
            continue
        if pkg[0] == '-':
            purge.add(pkg[1:])
        else:
            install.add(pkg)
    # Purge overrides install
    install = install - purge

    info = {'install': list(install), 'purge': list(purge)}
    return {'install': info}
