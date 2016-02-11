
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
    
    if $::cfauth::sudo_no_password_all {
        $sudo_content = "${admin_user}   ALL=(ALL:ALL) NOPASSWD: ALL"
    } else {
        $sudo_content = '
<%= ${cfauth::admin_user} %>   ALL=(ALL:ALL) ALL
<%= ${cfauth::admin_user} %>   ALL=(ALL:ALL) NOPASSWD: \
/opt/puppetlabs/puppet/bin/puppet agent --test
<%= ${cfauth::admin_user} %>   ALL=(ALL:ALL) NOPASSWD: \
/usr/bin/apt-get update
<%= ${cfauth::admin_user} %>   ALL=(ALL:ALL) NOPASSWD: \
/usr/bin/apt-get dist-upgrade *
<% ${cfauth::sudo_no_password_commands}.each |cmd| { -%>
<%= ${cfauth::admin_user} %>   ALL=(ALL:ALL) NOPASSWD: <%= $cmd  %>
<% } -%>
'
    }
    
    file {"/etc/sudoers.d/${admin_user}":
        group => root,
        owner => root,
        mode => '0400',
        replace => true,
        content => inline_epp($sudo_content),
    }
}
