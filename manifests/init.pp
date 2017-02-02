#
# Copyright 2016-2017 (c) Andrey Galkin
#


# Please see README
class cfauth (
    Optional[Hash[String[1], Hash]]
        $admin_auth_keys,
    String[1]
        $admin_user = 'adminaccess',
    Optional[String[1]]
        $admin_password = undef, # mkpasswd -m sha-512 
    Optional[Variant[String[1], Array[String[1]]]]
        $admin_hosts = undef, # hosts to whitelist for SSH access
    Boolean
        $sudo_no_password_all = false,
    Array[String[1]]
        $sudo_no_password_commands = [],
    Array[String[1]]
        $sudo_env_keep = [],
    Variant[Integer[1,65535], Array[Integer[1,65535]]]
        $sshd_ports = 22,
    String[1]
        $sshd_config_template = 'cfauth/sshd_config.epp',
) {
    include stdlib
    include cfnetwork

    $sudo_no_password_commands_all = [
        '/opt/puppetlabs/puppet/bin/puppet agent --test *',
        '/usr/bin/apt-get update *',
        '/usr/bin/apt-get dist-upgrade *',
        '/usr/bin/apt-get autoremove *',
    ] + pick_default($sudo_no_password_commands, [])

    $sudo_env_keep_all = [
        'DEBIAN_FRONTEND',
    ] + pick_default($sudo_env_keep, [])

    class {'cfauth::details::root':
        stage => 'setup',
    }

    include cfauth::details::admin

    package { 'sudo': }
    package { 'openssh-server': }
    service{ 'ssh':
        ensure   => running,
        enable   => true,
        provider => 'systemd',
    }

    file {'/etc/ssh/sshd_config':
        group   => root,
        owner   => root,
        mode    => '0600',
        content => epp($sshd_config_template, {
            sshd_ports => $sshd_ports,
        }),
        require => [ Group['ssh_access'], Package['openssh-server'] ],
        notify  => Service['ssh'],
    }

    # Configure firewall
    #---
    $fw_ports = prefix(any2array($sshd_ports), 'tcp/')
    cfnetwork::describe_service { 'cfssh':
        server => $fw_ports,
    }
    cfnetwork::ipset { 'cfauth_admin':
        type    => 'net',
        addr    => $::cfauth::admin_hosts,
        dynamic => true,
    }
    cfnetwork::service_port { 'any:cfssh:cfauth':
        src => 'ipset:cfauth_admin',
    }

    # Populate global whitelist
    #---
    cfnetwork::ipset { 'whitelist:cfauth':
        type => 'net',
        addr => 'ipset:cfauth_admin',
    }
}
