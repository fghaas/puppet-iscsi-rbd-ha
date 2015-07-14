define iscsirbdha::rbdresource (
  $volume = $name,
  $pool = 'rbd',
  $ensure = 'present',
  $monitor_interval = '10s'
) {
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
}
