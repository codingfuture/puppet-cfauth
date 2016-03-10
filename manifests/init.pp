
class cfauth (
    $admin_auth_keys,
    $admin_user = 'adminaccess',
    $admin_password = undef, # mkpasswd -m sha-512 
    $admin_hosts = undef, # hosts to whitelist for SSH access
    $sudo_no_password_all = false,
    $sudo_no_password_commands = [],
    $sudo_env_keep = [],
    $sshd_ports = '22',
    $sshd_config_template = 'cfauth/sshd_config.epp',
) {
    include stdlib
    include cfnetwork
    
    $sudo_no_password_commands_all = [
        '/opt/puppetlabs/puppet/bin/puppet agent --test',
        '/usr/bin/apt-get update',
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
    service{ 'ssh': ensure => running }
    
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
    
    $fw_ports = prefix(any2array($sshd_ports), 'tcp/')
    cfnetwork::describe_service { 'cfssh':
        server => $fw_ports,
    }
    cfnetwork::service_port { 'any:cfssh:cfauth':
        src => $admin_hosts,
    }
}