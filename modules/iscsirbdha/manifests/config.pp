define iscsirbdha::config (
  $vip,
  $iqn,
  $volumes = {},
  $monitor_interval = '10s',
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

  $lu_defaults = {
    iqn => $iqn,
    ensure => $ensure,
    target_name => $name,
    monitor_interval => $monitor_interval,
  }

  create_resources('iscsirbdha::rbdluresourcegroup', $volumes, $lu_defaults)
}
