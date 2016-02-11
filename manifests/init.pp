
class cfauth (
    $admin_auth_keys,
    $admin_user = 'adminaccess',
    $admin_password = undef, # mkpasswd -m sha-512 
    $admin_hosts = undef, # hosts to whitelist for SSH access
    $sudo_no_password_all = false,
    $sudo_no_password_commands = [],
    $sshd_ports = '22',
    $sshd_config_template = 'cfauth/sshd_config.epp',
) {
    include cfnetwork
    
    class {'cfauth::details::root':
        stage => 'setup',
    }
    
    include cfauth::details::admin
    
    service{ 'ssh': ensure => running }
    
    file {'/etc/ssh/sshd_config':
        group => root,
        owner => root,
        mode => '0600',
        content => epp($sshd_config_template, {
            sshd_ports => $sshd_ports,
        }),
        require => Group['ssh_access'],
        notify => Service['ssh'],
    }
    
    $fw_ports = prefix($sshd_ports, 'tcp/')
    cfnetwork::describe_service { 'cfssh':
        server => $fw_ports,
    }
    cfnetwork::service_port { 'any:cfssh:cfauth':
        src => $admin_hosts,
    }
}