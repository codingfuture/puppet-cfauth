
# Please see README
class cfauth::details::admin {
    assert_private()

    $admin_user = $::cfauth::admin_user
    $admin_password = $::cfauth::admin_password
    $admin_auth_keys = $::cfauth::admin_auth_keys

    group {$admin_user: ensure => present }
    user {$admin_user:
        ensure         => present,
        gid            => $admin_user,
        groups         => ['sudo', 'ssh_access'],
        managehome     => true,
        home           => "/home/${admin_user}",
        password       => $admin_password,
        purge_ssh_keys => true,
        shell          => '/bin/bash',
        require        => [ Package['sudo'], Group['ssh_access'] ],
    }
    mailalias{$admin_user:
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

    file {"/etc/sudoers.d/${admin_user}":
        group   => root,
        owner   => root,
        mode    => '0400',
        replace => true,
        content => epp('cfauth/sudoers.epp'),
        require => Package['sudo'],
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
