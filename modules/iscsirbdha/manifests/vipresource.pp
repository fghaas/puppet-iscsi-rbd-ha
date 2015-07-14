define iscsirbdha::vipresource (
  $ipaddr = $name,
  $netmask = 24,
  $monitor_interval = '10s',
  $ensure = 'present'
) {

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
}
