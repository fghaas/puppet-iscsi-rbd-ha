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
  rbdresource { "${pool}/${volume}":
    ensure => $ensure,
    volume => $volume,
    pool => $pool,
    monitor_interval => $monitor_interval,
  }
  luresource { "${pool}/${volume}":
    ensure => $ensure,
    iqn => $iqn,
    volume => $volume,
    pool => $pool,
    iblock => $iblock,
    monitor_interval => $monitor_interval,
  }
  cs_group { "g_${name}":
    ensure          => $ensure,
    primitives      => ["p_vip_${name}",
                        "p_target_${name}",
                        "p_rbd_${pool}_${name}",
                        "p_lu_${pool}_${name}",],
  }
}
