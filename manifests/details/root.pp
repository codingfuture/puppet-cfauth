#
# Copyright 2016-2019 (c) Andrey Galkin
#


# Please see README
class cfauth::details::root {
    assert_private()

    user {'root':
        password => $::cfauth::admin_password,
        home     => '/root',
    }
    group { ['ssh_access', 'sftp_only', 'wheel']:
        ensure => present,
    }
}
