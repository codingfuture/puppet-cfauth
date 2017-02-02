#
# Copyright 2017 (c) Andrey Galkin
#

define cfauth::sudoentry(
    Variant[String[1], Array[String[1]]]
        $command,
    Variant[String[1], Array[String[1]]]
        $env_keep = [],
    String[1]
        $user = $title,
) {
    file {"/etc/sudoers.d/${title}":
        group   => root,
        owner   => root,
        mode    => '0440',
        replace => true,
        content => epp('cfauth/sudoers.epp', {
            user     => $user,
            cmds     => any2array($command),
            env_keep => any2array($env_keep),
        }),
    }
}
