#
# Copyright 2018 (c) Andrey Galkin
#


define cfauth::sftp::user(
    Hash[String[1], Hash]
        $auth_keys = {},
    Array[String[1]]
        $user_hosts = [],
    Optional[Variant[String[1],Integer]]
        $block_limit = undef,
    Optional[Variant[String[1],Integer]]
        $inode_limit = undef,
) {
    include cfauth::sftp

    $sftp_user = "sftp_${name}"
    $home_root = $cfauth::sftp::home_root
    $home_dir = "${home_root}/${sftp_user}"
    $chroot_dir = "${cfauth::sftp::chroot_root}/${sftp_user}"

    group { $sftp_user:
        ensure => present,
    }
    -> user { $sftp_user:
        ensure         => present,
        gid            => $sftp_user,
        groups         => ['sftp_only'],
        managehome     => true,
        home           => $home_dir,
        purge_ssh_keys => true,
        shell          => '/usr/bin/rssh',
        require        => [
            Group['sftp_only'],
            Package['rssh'],
        ],
    }
    -> mailalias{$sftp_user:
        recipient => 'root',
    }
    ->file { $chroot_dir:
        ensure => directory,
        owner  => root,
        mode   => '0711',
    }
    ->file { "${chroot_dir}/dev":
        ensure => directory,
        owner  => root,
        mode   => '0711',
    }
    ->file { "${chroot_dir}/data":
        ensure => directory,
        owner  => $sftp_user,
        group  => $sftp_user,
        mode   => '0750',
    }
    ->file { "/etc/rsyslog.d/${sftp_user}.conf":
        ensure  => file,
        mode    => '0640',
        content => "input(type=\"imuxsock\" Socket=\"${chroot_dir}/dev/log\")",
        notify  => Exec[ 'cfauth:rsyslog:refresh' ],
    }

    create_resources(
        ssh_authorized_key,
        prefix($auth_keys, "${sftp_user}@"),
        {
            user    => $sftp_user,
            'type'  => 'ssh-rsa',
            options => [
                "from=\"${user_hosts.join(',')}\"",
            ],
            require => User[$sftp_user],
        }
    )

    cfnetwork::ipset { "cfauth_sftp:${name}":
        type    => 'net',
        addr    => $user_hosts,
        dynamic => true,
    }

    if $block_limit or $inode_limit {
        ensure_packages( [ 'quota' ] )

        $quota_mark = "blocks=${block_limit} inodes=${inode_limit}"
        $mark_file = "${home_dir}_quota.mark"

        exec { "Set ${sftp_user} quota: ${quota_mark}":
            command => [
                "/usr/sbin/setquota -u ${sftp_user} 1G 1G 10k 10k \$(/usr/bin/stat -c '%m' ${chroot_dir})",
                "/bin/echo -n '${quota_mark}' > ${mark_file}"
            ].join( ' && ' ),
            unless  => "/bin/grep -q '${quota_mark}' ${mark_file}",
            require => [
                User[$sftp_user],
            ],
        }
    }
}
