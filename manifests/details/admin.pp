#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfauth::details::admin {
    assert_private()

    $admin_user = $::cfauth::admin_user
    $admin_password = $::cfauth::admin_password
    $admin_auth_keys = $::cfauth::admin_auth_keys

    group { $admin_user:
        ensure => present,
    }
    -> user { $admin_user:
        ensure         => present,
        gid            => $admin_user,
        groups         => ['sudo', 'ssh_access'],
        managehome     => true,
        home           => "/home/${admin_user}",
        password       => $admin_password,
        purge_ssh_keys => true,
        shell          => '/bin/bash',
        require        => [
            Package['sudo'],
            Group['ssh_access']
        ],
    }
    -> mailalias{$admin_user:
        recipient => 'root',
    }

    if $admin_auth_keys {
        create_resources(
            ssh_authorized_key,
            prefix($admin_auth_keys, "${admin_user}@"),
            {
                user => $admin_user,
                'type' => 'ssh-rsa',
                require => User[$admin_user],
            }
        )
    }

    $admin_cmds = $cfauth::sudo_no_password_all ? {
        true => 'ALL',
        default => $cfauth::sudo_no_password_commands_all,
    }

    cfauth::sudoentry { $admin_user:
        command => $admin_cmds,
    }

    # Make to conflict with any mistaken permission change
    if !defined(File['/home']) {
        file { '/home':
            ensure => directory,
            owner  => root,
            group  => root,
            mode   => '0755',
        }
    }
}
