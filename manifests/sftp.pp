#
# Copyright 2018 (c) Andrey Galkin
#


class cfauth::sftp (
    String[1] $root = '/mnt/sftp',

    Hash[String[1], Hash]
        $users = {},

    Variant[Cfnetwork::Port, Array[Cfnetwork::Port]]
        $sshd_ports = 22,
) {
    include cfauth

    $home_root = "${root}/home"
    $chroot_root = "${root}/chroot"

    file { [ $root, $home_root, $chroot_root ]:
        ensure => directory,
        mode   => '0711',
    }
    -> file { '/var/sftp_only':
        ensure => link,
        target => $root,
    }

    ensure_packages( ['rssh'] )
    create_resources( 'cfauth::sftp::user', $users )

    # Configure firewall
    #---
    $fw_ports = prefix(any2array($sshd_ports), 'tcp/')
    cfnetwork::describe_service { 'cfsftp':
        server => $fw_ports,
    }
    cfnetwork::ipset { 'cfauth_sftp':
        type    => 'net',
        addr    => [],
        dynamic => true,
    }
    cfnetwork::service_port { 'any:cfsftp:cfauth':
        src => 'ipset:cfauth_sftp',
    }

    exec { 'cfauth:rsyslog:refresh':
        command     => '/bin/systemctl reload-or-restart rsyslog.service',
        refreshonly => true,
    }
}
