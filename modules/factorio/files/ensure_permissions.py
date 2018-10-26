#!/usr/bin/python
# This script ensures the permissions of the Factorio game files are sane,
# otherwise the server wont start.
import os
import sys
from os import stat
from pwd import getpwuid


def build_file_list(path='/home/factorio/factorio'):
    file_list = []
    for dirname, dirnames, filenames in os.walk(path):
        # print path to all subdirectories first.
        for subdirname in dirnames:
            file_list.append((os.path.join(dirname, subdirname)))

        # print path to all filenames.
        for filename in filenames:
            file_list.append((os.path.join(dirname, filename)))
    return file_list


def check_perms(filename):
    return getpwuid(stat(filename).st_uid).pw_name


for core_file in build_file_list():
        if check_perms(core_file) == 'factorio':
                pass
        else:
                sys.exit(1)

# vim: ts=4: sts=4: sw=4: expandtab
