define iscsirbdha::luresource (
  $volume = $name,
  $pool = 'rbd',
  $iqn,
  $iblock,
  $monitor_interval = '10s',
  $ensure = 'present'
) {
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
}
