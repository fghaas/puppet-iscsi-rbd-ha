class iscsirbdha (
  $authkey_source,
  $authkey,
  $multicast_address,
  $quorum_members,
  $targets,
  $stonith = false
) {

  include ceph::profile::client

  package { 'targetcli':
    ensure  => latest,
  }
  class { 'corosync':
    enable_secauth    => true,
    authkey_source    => $authkey_source,
    authkey           => $authkey,
    multicast_address => $multicast_address,
    quorum_members    => $quorum_members,
  }
  service { 'pacemaker':
    ensure => running,
    require => Class['corosync'],
  }

  Service['pacemaker'] -> Cs_location<| |>
  Service['pacemaker'] -> Cs_property<| |>
  Service['pacemaker'] -> Cs_primitive<| |>
  Service['pacemaker'] -> Cs_group<| |>

  service { 'target':
    ensure => running,
    require => Package['targetcli'],
  }
  cs_property { 'stonith-enabled' :
    value   => bool2str($stonith),
  }

  file { 'resource-agent-directory':
    ensure => directory,
    path => '/usr/lib/ocf/resource.d/ceph',
    mode => '0755',
  }

  file { 'rbd-resource-agent':
    ensure => present,
    path => '/usr/lib/ocf/resource.d/ceph/rbd',
    mode => '0755',
    source => 'puppet:///modules/iscsirbdha/rbd',
    require => File['resource-agent-directory'],
  }
  create_resources(iscsirbdha::config, $targets)
}
