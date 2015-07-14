define iscsirbdha::rbdluresourcegroup (
  $volume = $name,
  $pool = 'rbd',
  $iqn,
  $target_name,
  $iblock = 0,
  $ensure = 'present',
  $monitor_interval = '10s'
) {
  iscsirbdha::rbdresource { "${pool}/${volume}":
    ensure => $ensure,
    volume => $volume,
    pool => $pool,
    monitor_interval => $monitor_interval,
  }
  iscsirbdha::luresource { "${pool}/${volume}":
    ensure => $ensure,
    iqn => $iqn,
    volume => $volume,
    pool => $pool,
    iblock => $iblock,
    monitor_interval => $monitor_interval,
    require => Iscsirbdha::Rbdresource["${pool}/${volume}"],
  }
  cs_group { "g_${pool}_${volume}":
    ensure          => $ensure,
    primitives      => ["p_rbd_${pool}_${volume}",
                        "p_lu_${pool}_${volume}",],
  }
  cs_order { "o_${target_name}_before_${pool}_${volume}":
    first   => "g_${target_name}",
    second  => "g_${pool}_${volume}",
    require => Cs_group["g_${target_name}",
                        "g_${pool}_${volume}"],
  }
  cs_colocation { "c_${pool}_${volume}_on_${target_name}":
    primitives => [ "g_${target_name}",
                    "g_${pool}_${volume}" ],
    require => Cs_group["g_${target_name}",
                        "g_${pool}_${volume}"],
  }
}
