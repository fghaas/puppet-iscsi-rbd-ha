define iscsirbdha::config (
  $vip,
  $iqn,
  $volume,
  $pool = 'rbd',
  $monitor_interval = '10s',
  $iblock = 0,
  $port = 3260,
  $ensure = 'present'
) {

  # Break the VIP into its IP address and CIDR netmask
  $viparray = split($vip, '/')
  $ipaddr = $viparray[0]
  $netmask = $viparray[1]

  cs_primitive { "p_vip_${name}":
    ensure          => $ensure,
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
  }
  cs_primitive { "p_target_${name}":
    ensure          => $ensure,
    primitive_class => 'ocf',
    primitive_type  => 'iSCSITarget',
    provided_by     => 'heartbeat',
    parameters      => {
      'implementation' => 'lio-t',
      'iqn' => $iqn,
      'portals' => "${ipaddr}:${port}",
    },
    operations      => {
      'monitor' => {
        'interval' => $monitor_interval
        }
    },
    require         => [Service['target'],
                        Cs_primitive["p_vip_${name}"]]
  }
  cs_primitive { "p_rbd_${name}":
    ensure          => $ensure,
    primitive_class => 'ocf',
    primitive_type  => 'rbd',
    provided_by     => 'ceph',
    parameters      => {
      'name' => $volume,
      'pool' => $pool,
    },
    operations      => {
      'monitor' => {
        'interval' => $monitor_interval
        }
    },
  }
  cs_primitive { "p_lu_${name}":
    ensure          => $ensure,
    primitive_class => 'ocf',
    primitive_type  => 'iSCSILogicalUnit',
    provided_by     => 'heartbeat',
    parameters      => {
      'implementation' => 'lio-t',
      'target_iqn' => $iqn,
      'lun' => 1,
      'path' => "/dev/rbd/${pool}/${volume}",
      'lio_iblock' => $iblock
    },
    operations      => {
      'monitor' => {
        'interval' => $monitor_interval
        }
    },
  }
  cs_group { "g_${name}":
    ensure          => $ensure,
    primitives      => ["p_vip_${name}",
                        "p_target_${name}",
                        "p_rbd_${name}",
                        "p_lu_${name}",],
  }
}
