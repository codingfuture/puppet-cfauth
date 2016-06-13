class cfauth::details::root {
    user {'root':
        password => $::cfauth::admin_password,
        home     => '/root',
    }
    group {'ssh_access': ensure => present }
}
