node puppetmaster {
  include puppetmaster
}

node /^ceph\d+$/ {
  include ceph::profile::mon
  include ceph::profile::osd
}

node /^iscsi\d+$/ {
  include iscsirbdhacluster
}

class puppetmaster {
  service { 'puppetmaster':
    ensure => 'running',
  }
}

class iscsirbdhacluster (
  $authkey_source,
  $authkey,
  $multicast_address,
  $quorum_members,
  $targets,
  $stonith = false
) {

  include ceph::profile::client

  # ceph::repo relies on the availability of
  # $::operatingsystemmajrelease, which is broken with
  # centos-release-7-1.1503.el7.centos.2.7. So, make sure we upgrade
  # centos-release before creating Ceph repos.
  package { 'centos-release':
    ensure => latest,
  }
  Package['centos-release'] -> Class['ceph::repo']

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

  create_resources(iscsirbdha, $targets)
}

define iscsirbdha (
  $vip,
  $iqn,
  $path,
  $monitor_interval = '10s',
  $iblock = 0,
  $ensure = 'present'
) {

  # Break the VIP into its IP address and CIDR netmask
  $viparray = split($vip, '/')
  $ipaddr = $viparray[0]
  $netmask = $viparray[1]

  cs_primitive { "p_vip_${name}":
    primitive_class => 'ocf',
    primitive_type  => 'IPaddr2',
    provided_by     => 'heartbeat',
    parameters      => {
      'ip' => $ipaddr,
      'cidr_netmask' => $netmask,
    },
    operations      => {
      'monitor' => {
        'interval' => $monitor_interval,
      }
    },
    ensure          => $ensure,
  }
  cs_primitive { "p_target_${name}":
    primitive_class => 'ocf',
    primitive_type  => 'iSCSITarget',
    provided_by     => 'heartbeat',
    parameters      => {
      'implementation' => 'lio-t',
      'iqn' => $iqn
    },
    operations      => {
      'monitor' => {
        'interval' => $monitor_interval
        }
    },
    require         => Service['target'],
    ensure          => $ensure,
  }
  cs_primitive { "p_lu_${name}":
    primitive_class => 'ocf',
    primitive_type  => 'iSCSILogicalUnit',
    provided_by     => 'heartbeat',
    parameters      => {
      'implementation' => 'lio-t',
      'target_iqn' => $iqn,
      'lun' => 1,
      'path' => $path,
      'lio_iblock' => $iblock
    },
    operations      => {
      'monitor' => {
        'interval' => $monitor_interval
        }
    },
    ensure          => $ensure,
  }
  cs_group { "g_${name}":
    primitives      => ["p_target_${name}",
                        "p_lu_${name}",
                        "p_vip_${name}" ],
    ensure          => $ensure,
  }
}
