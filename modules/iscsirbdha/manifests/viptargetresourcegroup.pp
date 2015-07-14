define iscsirbdha::viptargetresourcegroup (
  $vip = undef,
  $iqn = $name,
  $monitor_interval = '10s',
  $port = 3260,
  $ensure = 'present'
) {

  if $vip {
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
  } else {
    iscsirbdha::targetresource { $name:
      iqn => $iqn,
      ensure => $ensure,
      monitor_interval => $monitor_interval,
    }
    cs_group { "g_${name}":
      ensure          => $ensure,
      primitives      => ["p_target_${name}",],
    }
  }

  cs_order { "o_target_service_before_${name}":
    ensure => $ensure,
    first   => 'p_target_service-clone',
    second  => "g_${name}",
    require => [Cs_clone['p_target_service-clone'],
                Cs_group["g_${name}"],],
  }
  cs_colocation { "c_${name}_on_target_service":
    ensure => $ensure,
    primitives => [ "g_${name}",
                    'p_target_service-clone',],
    require => [Cs_group["g_${name}"],
                Cs_clone['p_target_service-clone'],],
  }
}
