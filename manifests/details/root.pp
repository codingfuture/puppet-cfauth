
# Please see README
class cfauth::details::root {
    assert_private()

    user {'root':
        password => $::cfauth::admin_password,
        home     => '/root',
    }
    group {'ssh_access': ensure => present }
}
