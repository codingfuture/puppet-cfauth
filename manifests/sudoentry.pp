#
# Copyright 2017 (c) Andrey Galkin
#

define cfauth::sudoentry(
    Variant[String[1], Array[String[1]]]
        $command,
    String[1]
        $user = $cfauth::admin_user,
) {
    if !$cfauth::sudo_no_password_all {
        $lines = any2array($command).map |$cmd| {
            "${user}   ALL=(ALL:ALL) NOPASSWD: ${cmd}"
        }

        file {"/etc/sudoers.d/${title}":
            group   => root,
            owner   => root,
            mode    => '0400',
            replace => true,
            content => ($lines << '').join("\n"),
            require => Package['sudo'],
        }
    }
}
