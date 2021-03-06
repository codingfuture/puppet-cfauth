#
# Copyright 2016-2019 (c) Andrey Galkin
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
    Variant[Cfnetwork::Port, Array[Cfnetwork::Port]]
        $sshd_ports = 22,
    String[1]
        $sshd_config_template = 'cfauth/sshd_config.epp',
    Hash[String[1], Hash]
        $sudo_entries = {},
    Boolean
        $clear_sudoers = true,
    Array[String[0]]
        $custom_sudoers = [],
    Array[String[1]]
        $secure_path = [
            '/usr/local/sbin',
            '/usr/local/bin',
            '/usr/sbin',
            '/usr/bin',
            '/sbin',
            '/bin',
        ],
    Variant[Integer, String[1]]
        $ssh_max_startups = 10,
    Optional[Struct[{
        server => String[1],
        domain => String[1],
        groups => Variant[
            Pattern[/^[a-z][a-z0-9_]+$/],
            Array[Pattern[/^[a-z][a-z0-9_]+$/]],
        ],
    }]]
        $freeipa = undef,
) {
    include stdlib
    include cfnetwork

    $sudo_no_password_commands_all = [
        '/opt/puppetlabs/puppet/bin/puppet agent --test',
        '/opt/puppetlabs/puppet/bin/puppet agent --test *',
        '/usr/bin/apt-get update',
        '/usr/bin/apt-get update *',
        '/usr/bin/apt-get dist-upgrade',
        '/usr/bin/apt-get dist-upgrade *',
        '/usr/bin/apt-get autoremove',
        '/usr/bin/apt-get autoremove *',
    ] + pick_default($sudo_no_password_commands, [])

    $sudo_env_keep_all = [
        'DEBIAN_FRONTEND',
    ] + pick_default($sudo_env_keep, [])

    class {'cfauth::details::root':
        stage => 'setup',
    }

    include cfauth::details::admin

    # sudo
    #---
    ensure_packages(['sudo'])
    Package['sudo']
    -> file { '/etc/sudoers.d':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0755',
        purge   => $clear_sudoers,
        recurse => true,
    }

    create_resources('cfauth::sudoentry', $sudo_entries)

    if $clear_sudoers {
        file { '/etc/sudoers':
            owner   => 'root',
            group   => 'root',
            mode    => '0440',
            content => epp('cfauth/sudoers_global.epp')
        }
    }

    # SSH server
    #---
    package { 'openssh-server': }
    -> file {'/etc/ssh/sshd_config':
        group   => root,
        owner   => root,
        mode    => '0600',
        content => epp($sshd_config_template, {
            sshd_ports   => $sshd_ports,
            max_startups => $ssh_max_startups,
            freeipa      => $freeipa,
        }),
        require => [
            Group['ssh_access'],
            Group['sftp_only'],
            Package['openssh-server'],
        ],
        notify  => Service['ssh'],
    }
    -> service{ 'ssh':
        ensure   => running,
        enable   => true,
        provider => 'systemd',
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

    # Configure as FreeIPA client
    #---
    $freeipa_packages = ['freeipa-client', 'sssd', 'sssd-tools']

    if $freeipa {
        cfnetwork::describe_service { 'cfkerberos':
            server => [
                'tcp/88',
                'tcp/464',
                'udp/88',
                'udp/464',
            ],
        }
        cfnetwork::describe_service { 'cfldap':
            server => [
                'tcp/389',
                'tcp/636',
            ],
        }
        cfnetwork::client_port { 'any:cfkerberos:cfauth':
            user => 'root',
            dst  => $freeipa['server'],
        }
        cfnetwork::client_port { 'any:cfldap:cfauth':
            user => 'root',
            dst  => $freeipa['server'],
        }
        package { $freeipa_packages: }
        -> File['/etc/ssh/sshd_config']
    } else {
        package { $freeipa_packages:
            ensure => absent,
        }
        -> exec { 'freeipa-cleanup':
            command => '/bin/sed -i -e "s/ sss//g" /etc/nsswitch.conf',
            onlyif  => '/bin/grep -q " sss" /etc/nsswitch.conf',
        }
    }
}
