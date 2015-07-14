define iscsirbdha::viptargetresourcegroup (
  $vip,
  $iqn = $name,
  $monitor_interval = '10s',
  $port = 3260,
  $ensure = 'present'
) {
  # Break the VIP into its IP address and CIDR netmask
  $viparray = split($vip, '/')
  $ipaddr = $viparray[0]
  $netmask = $viparray[1]

  iscsirbdha::vipresource { $name:
    ensure => $ensure,
    ipaddr => $ipaddr,
    netmask => $netmask,
    monitor_interval => $monitor_interval,
  }
  iscsirbdha::targetresource { $name:
    iqn => $iqn,
    ensure => $ensure,
    monitor_interval => $monitor_interval,
    portals => "${ipaddr}:${port}",
    require => Iscsirbdha::Vipresource[$name],
  }
  cs_group { "g_${name}":
    ensure          => $ensure,
    primitives      => ["p_vip_${name}",
                        "p_target_${name}",],
  }
}
