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
  Service['pacemaker'] -> Cs_colocation<| |>
  Service['pacemaker'] -> Cs_order<| |>
  Service['pacemaker'] -> Cs_property<| |>
  Service['pacemaker'] -> Cs_primitive<| |>
  Service['pacemaker'] -> Cs_group<| |>

  cs_property { 'stonith-enabled' :
    value   => bool2str($stonith),
  }

  cs_primitive { 'p_target_service':
    ensure          => $ensure,
    primitive_class => 'systemd',
    primitive_type  => 'target',
    operations      => {
      'monitor' => {
        'interval' => '10s',
      }
    },
    require => Package['targetcli'],
  }
  cs_clone { 'p_target_service-clone':
    ensure    => $ensure,
    primitive => 'p_target_service',
    require   => Cs_primitive['p_target_service'],
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
    require => [File['resource-agent-directory'],
                Class['ceph::profile::client']],
  }
  create_resources(iscsirbdha::config, $targets)
}
