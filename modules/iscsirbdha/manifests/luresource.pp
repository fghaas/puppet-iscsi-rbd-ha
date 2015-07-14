define iscsirbdha::luresource (
  $volume = $name,
  $pool = 'rbd',
  $iqn,
  $lun = 0,
  $monitor_interval = '10s',
  $ensure = 'present'
) {
  cs_primitive { "p_lu_${pool}_${volume}":
    ensure          => $ensure,
    primitive_class => 'ocf',
    primitive_type  => 'iSCSILogicalUnit',
    provided_by     => 'heartbeat',
    parameters      => {
      'implementation' => 'lio-t',
      'target_iqn' => $iqn,
      'lun' => $lun,
      'path' => "/dev/rbd/${pool}/${volume}",
    },
    operations      => {
      'monitor' => {
        'interval' => $monitor_interval
        }
    },
  }
}
