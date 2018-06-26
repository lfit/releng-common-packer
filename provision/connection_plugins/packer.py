# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

from __future__ import (absolute_import, division, print_function)
__metaclass__ = type

from ansible.plugins.connection.ssh import Connection as SSHConnection

class Connection(SSHConnection):
    '''ssh based connections for powershell via packer'''

    transport = 'packer'
    has_pipelining = True
    become_methods = []
    allow_executable = False
    module_implementation_preferences = ('.ps1', '')

    def __init__(self, *args, **kwargs):
        super(Connection, self).__init__(*args, **kwargs)
