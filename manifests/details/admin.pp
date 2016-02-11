
class cfauth::details::admin {
    $admin_user = $::cfauth::admin_user
    $admin_password = $::cfauth::admin_password
    $admin_auth_keys = $::cfauth::admin_auth_keys
    
    group {$admin_user: ensure => present }
    user {$admin_user:
        ensure => present,
        gid => $admin_user,
        groups => ['sudo', 'ssh_access'],
        managehome => true,
        home => "/home/${admin_user}",
        password => $admin_password,
        purge_ssh_keys => true,
        shell => '/bin/bash',
        require => [ Package['sudo'], Group['ssh_access'] ],
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
    
    if $::cfauth::sudo_no_password {
        $sudo_content = "${admin_user}   ALL=(ALL:ALL) NOPASSWD: ALL"
    } else {
        $sudo_content = "
${admin_user}   ALL=(ALL:ALL) ALL
${admin_user}   ALL=(ALL:ALL) NOPASSWD: \
/opt/puppetlabs/puppet/bin/puppet agent --test
${admin_user}   ALL=(ALL:ALL) NOPASSWD: \
/usr/bin/apt-get update
${admin_user}   ALL=(ALL:ALL) NOPASSWD: \
/usr/bin/apt-get dist-upgrade *

"
    }
    
    file {"/etc/sudoers.d/${admin_user}":
        group => root,
        owner => root,
        mode => '0400',
        replace => true,
        content => $sudo_content,
    }
}
