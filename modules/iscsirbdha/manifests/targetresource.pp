define iscsirbdha::targetresource (
  $iqn = $name,
  $ensure = 'present',
  $monitor_interval = '10s',
  $ensure = 'present',
  $portals = '',
) {
  cs_primitive { "p_target_${name}":
    ensure          => $ensure,
    primitive_class => 'ocf',
    primitive_type  => 'iSCSITarget',
    provided_by     => 'heartbeat',
    parameters      => {
      'implementation' => 'lio-t',
      'iqn' => $iqn,
      'portals' => $portals,
    },
    operations      => {
      'monitor' => {
        'interval' => $monitor_interval
        }
    },
    require         => [Service['target']]
  }
}
