define iscsirbdha::rbdluresourcegroup (
  $volume = $name,
  $pool = 'rbd',
  $iqn,
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
}
