define iscsirbdha::rbdluresourcegroup (
  $volume = $name,
  $pool = 'rbd',
  $user = undef,
  $iqn,
  $target_name,
  $lun = 0,
  $ensure = 'present',
  $monitor_interval = '10s'
) {
  iscsirbdha::rbdresource { "${pool}/${volume}":
    ensure => $ensure,
    volume => $volume,
    pool => $pool,
    user => $user,
    monitor_interval => $monitor_interval,
  }
  iscsirbdha::luresource { "${pool}/${volume}":
    ensure => $ensure,
    iqn => $iqn,
    volume => $volume,
    pool => $pool,
    lun => $lun,
    monitor_interval => $monitor_interval,
    require => Iscsirbdha::Rbdresource["${pool}/${volume}"],
  }
  cs_group { "g_${pool}_${volume}":
    ensure          => $ensure,
    primitives      => ["p_rbd_${pool}_${volume}",
                        "p_lu_${pool}_${volume}",],
  }
  cs_order { "o_${target_name}_before_${pool}_${volume}":
    ensure => $ensure,
    first   => "g_${target_name}",
    second  => "g_${pool}_${volume}",
    require => Cs_group["g_${target_name}",
                        "g_${pool}_${volume}"],
  }
  cs_colocation { "c_${pool}_${volume}_on_${target_name}":
    ensure => $ensure,
    primitives => [ "g_${pool}_${volume}",
                    "g_${target_name}",],
    require => Cs_group["g_${pool}_${volume}",
                        "g_${target_name}"],
  }
}
