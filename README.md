# cfauth

## Description

Generic configuration of system security:

* Update SSH config and strip unused features
* Enable only SSHv2 public key authentication
* Enable SSH login only for members of `ssh_access` group
* Create special user for admin access
* Setup encrypted admin password
* Setup sudoers
* Harden /bin/su to allow access only from wheel group
* Configure firewall for SSH access only from whitelisted hosts

## Technical Support

* [Example configuration](https://github.com/codingfuture/puppet-test)
* Free & Commercial support: [support@codingfuture.net](mailto:support@codingfuture.net)

## Setup

Up to date installation instructions are available in Puppet Forge: https://forge.puppet.com/codingfuture/cfauth

Please use [librarian-puppet](https://rubygems.org/gems/librarian-puppet/) or
[cfpuppetserver module](https://codingfuture.net/docs/cfpuppetserver) to deal with dependencies.

There is a known r10k issue [RK-3](https://tickets.puppetlabs.com/browse/RK-3) which prevents
automatic dependencies of dependencies installation.

## Examples

Please check [codingufuture/puppet-test](https://github.com/codingfuture/puppet-test) for
example of a complete infrastructure configuration and Vagrant provisioning.

## Implicitly created resources

```yaml
cfnetwork::describe_services:
    cfssh:
        server: prefix(any2array($cfauth::sshd_ports), 'tcp/')
cfnetwork::service_ports:
    'any:cfssh:cfauth':
        src: 'ipset:cfauth_admin'
cfnetwork::ipsets:
    cfauth_admin:
        type: net
        addr: $cfauth::admin_hosts
        dynamic: true
    whitelist:cfauth:
        type: net
        addr: 'ipset:cfauth_admin'
```

## `cfauth` parameters

* `admin_auth_keys` - mandatory required list of allowed SSH public keys in format
    of suitable for `create_resources(ssh_authorized_key, $admin_auth_keys, { user => $admin_user, type => 'ssh-rsa' })`.
* `admin_user = 'adminaccess'` - setup non-root user for SSH access capable of `sudo`
* `admin_password = undef` - encrypted password for `root` and `$admin_user`, if set
    *Note: use the following command for generation `mkpasswd -m sha-512`*
* `admin_hosts = undef` - passed as `src` paramter to `cfnetwork::service_port`
* `sudo_no_password_all = false` - allow `sudo` for `$admin_user` without password. See below.
* `sudo_no_password_commands` = []` - optional list of commands which are allowed to run without password
* `sudo_env_keep = []` - optional list of environment variables allowed to be preserved in sudo
* `sudo_entries = {}` - optional resources of type `cfauth::sudoentry`
* `clear_sudoers = true` - clear unmanaged /etc/sudoers.d
* `custom_sudoers = []` - arbitrary lines to add to global sudoers file
* `sshd_ports = '22'`,
* `sshd_config_template = 'cfauth/sshd_config.epp'`,
* `secure_path = [<system default>]` - array of global trusted paths
* `ssh_max_startups = 10` - parameter for SSH MaxStartups
* `freeipa = undef` - optional FreeIPA client support:
    - `server` - FreeIPA server address,
    - `domain` - FreeIPA domain,
    - `groups` - FreeIPA groups to allow SSH access.

### `sudo_no_password_all` purpose

Enabling it is useful for bulk administration of less privileged VMs.

Even if password is required, the following commands can be run without password:

* `/opt/puppetlabs/puppet/bin/puppet agent --test` - deploy puppet
* `/usr/bin/apt-get update` - update apt repository metadata
* `/usr/bin/apt-get dist-upgrade` - run system upgrade with optional parameter, like
    `-s -y` (for simulation( and `-y` (for install)
* `/usr/bin/apt-get autoremove` - run automatic unusued package remove
* `/usr/sbin/cfntpdate` - force run pre-configured ntpdate from `cfsystem` module

The following environment variables are allowed in sudo by default:
* `DEBIAN_FRONTEND`

## `cfauth::sudoentry` type

* `title` - name of file under '/etc/sudoers.d'
* `command = []` - command to allow to execute without password
    * String or Array of Strings
* `env_keep = []` - list of environment variables for env_keep
* `user = $cfauth::admin_user` - user for the entry
* `custom_config = []` - arbitrary lines to add

# SFTP only users

A standalone `cfauth::sftp` class has to be included.

All users are created with `sftp_` prefix. Their home folders are
located under `$cfauth::sftp::root/home`. All users are chrooted
under `$cfauth::sftp::root/chroot/%u`. Each use has `data` folder
under chroot - the default selected.

Note: if disk quota is configured then filesystem must be mounted
by any type of user quota support.

## `cfauth::sftp` class

* `root = '/mnt/sftp'` - root for SFTP location.
* `users = {}` - `cfauth::sftp::user` definitions

## `cfauth::sftp::user` type

* `name` - name of user without `sftp_` prefix.
* `auth_keys = {}` - definition of SSH authentication keys.
* `user_hosts = []` - list of SSH-accepted IP addresses to allow
    access from.
* `block_limit = undef` - passed to setquota hard block limit
* `inode_limit = undef` - passed to setquota hard inode limit

