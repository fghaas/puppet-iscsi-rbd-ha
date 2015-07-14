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

  iscsirbdha::viptargetresourcegroup { $name:
    ensure => $ensure,
    vip => $vip,
    port => $port,
    iqn => $iqn,
    monitor_interval => $monitor_interval,
  }
  iscsirbdha::rbdluresourcegroup { $name:
    ensure => $ensure,
    iqn => $iqn,
    volume => $volume,
    pool => $pool,
    iblock => $iblock,
    monitor_interval => $monitor_interval,
  }
}
