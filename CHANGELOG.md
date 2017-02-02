# Change Log

All notable changes to this project will be documented in this file. This
project adheres to [Semantic Versioning](http://semver.org/).

## [0.10.2]
- Added cfntpdate for passwordless execution

## [0.10.1]
- Fixed Debian Stretch support
- Updated to cfnetwork 0.10.1

## [0.10.0]
- Updated CF deps to v0.10.x
- Version bump

## [0.9.8]
- Updated to `cfnetwork` 0.9.11+ ipset support
- Added strict parameter type checking
- Automatic newer puppet-lint fixes
- Fixed puppet-lint and metadata-json-lint warnings

## [0.9.7]

- Changed to define root user with explicit home to be more friendly to cfdb

## [0.9.6]

- Updated supported OS list

## [0.9.5]

- Updated deps to latest versions

## [0.9.4]

- Added sudo_env_keep parameter support
- Added forceful /home folder permissions to avoid accidents with not accessible authorized_keys
- Added apt-get autoremove to list of sudo no password commands

## [0.9.3]

- Fixed to install sudo & openssh-server in cfauth instead of cfsystem
- Fixed dependency in deployment on bare system (after debootstrap)

## [0.9.2]

- Updated dependencies

## [0.9.1]

* Added hiera.yaml version 4 support

## [0.9.0]

Initial release

[0.10.2]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.10.2
[0.10.1]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.10.1
[0.10.0]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.10.0
[0.9.8]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.9.8
[0.9.7]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.9.7
[0.9.6]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.9.6
[0.9.5]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.9.5
[0.9.4]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.9.4
[0.9.3]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.9.3
[0.9.2]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.9.2
[0.9.1]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.9.1
[0.9.0]: https://github.com/codingfuture/puppet-cfauth/releases/tag/v0.9.0