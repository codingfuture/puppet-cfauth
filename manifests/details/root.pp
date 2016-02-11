class cfauth::details::root {
    user {'root':
        password => $::cfauth::admin_password,
    }
    group {'ssh_access': ensure => present }
}
