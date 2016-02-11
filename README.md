# cfauth

## Description

Generic configuration of system security:

* Update SSH config and strip unused features
* Enable only SSHv2 public key authentication
* Enable SSH login only for members of `ssh_access` group
* Create special user for admin access
* Setup encrypted admin password
* Setup sudoers
* Configure firewall for SSH access only from whitelisted hosts

## Setup

If r10k is used until [RK-3](https://tickets.puppetlabs.com/browse/RK-3) is solved, make
sure to have the following lines in Puppetfile:

```ruby
mod 'puppetlabs/stdlib', '4.11.0'
mod 'codingfuture/cfnetwork'
```

## `cfauth` parameters

* `admin_auth_keys - mandatory required list of allowed SSH public keys in format
    of suitable for `create_resources(ssh_authorized_key, $admin_auth_keys, { user => $admin_user, type => 'ssh-rsa' })`.
* `admin_user` = 'adminaccess' - setup non-root user for SSH access capable of `sudo`
* `admin_password` = undef - encrypted password for `root` and `$admin_user`, if set
    *Note: use the following command for generation `mkpasswd -m sha-512`*
* `admin_hosts` = undef - passed as `src` paramter to `cfnetwork::service_port`
* `sudo_no_password` = false - allow `sudo` for `$admin_user` without password. See below.
* `sshd_ports` = '22',
* `sshd_config_template` = 'cfauth/sshd_config.epp',

### `sudo_no_password` purpose

Enabling it is useful for bulk administration of less privileged VMs.

Even if password is required, the following commands can be run without password:

* `/opt/puppetlabs/puppet/bin/puppet agent --test` - deploy puppet
* `/usr/bin/apt-get update` - update apt repository metadata
* `/usr/bin/apt-get dist-upgrade *` - run system upgrade with optional parameter, like
    `-s -y` (for simulation( and `-y` (for install)

