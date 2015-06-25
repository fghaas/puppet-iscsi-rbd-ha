node puppetmaster {
  service { 'puppetmaster':
    ensure => 'running',
  }
}
node /^iscsi\d+$/ {

  include iscsirbdhacluster
}

class iscsirbdhacluster ($authkey_source,
                          $authkey,
                          $multicast_address,
                          $quorum_members,
                          $targets,
                          $stonith = false) {
  tidy { '/etc/yum.repos.d':
    matches => ['CentOS-*.repo'],
    recurse => true,
  }
  yumrepo { 'centos-base':
    mirrorlist => 'http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra',
    gpgcheck => 1,
    gpgkey => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7',
    exclude => 'ceph* python-rados* python-rbd* python-cephfs* python-ceph-compat* libcephfs* librados2* librbd1',
    require => Tidy['/etc/yum.repos.d'],
  }
  yumrepo { 'centos-updates':
    mirrorlist => 'http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra',
    gpgcheck => 1,
    gpgkey => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7',
    exclude => 'ceph* python-rados* python-rbd* python-cephfs* python-ceph-compat* libcephfs* librados2* librbd1',
    require => Tidy['/etc/yum.repos.d'],
  }
  yumrepo { 'ceph':
    baseurl  => 'http://ceph.com/rpm-firefly/rhel7/$basearch',
    descr    => 'Ceph packages for $basearch',
    enabled  => 1,
    gpgcheck => 1,
    gpgkey   => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
  }
  yumrepo { 'ceph-noarch':
    baseurl  => 'http://ceph.com/rpm-firefly/rhel7/noarch',
    descr    => 'Ceph packages for noarch',
    enabled  => 1,
    gpgcheck => 1,
    gpgkey   => 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc',
  }
  yumrepo { 'epel':
    baseurl  => 'http://download.fedoraproject.org/pub/epel/7/x86_64',
    descr    => 'EPEL',
    enabled  => 1,
    gpgcheck => 1,
    exclude => 'ceph* python-rados* python-rbd* python-cephfs* python-ceph-compat* libcephfs* librados2* librbd1',
    gpgkey   => 'https://getfedora.org/static/352C64E5.txt',
  }
  package { 'ceph':
    ensure  => latest,
    require => [ Yumrepo['centos-base', 'centos-updates', 'ceph', 'ceph-noarch', 'epel'] ],
  }
  package { 'targetcli':
    ensure  => latest,
    require => [ Yumrepo['centos-base', 'centos-updates'] ],
  }
  class { 'corosync':
    enable_secauth    => true,
    authkey_source    => $authkey_source,
    authkey           => $authkey,
    multicast_address => $multicast_address,
    quorum_members    => $quorum_members,
    require => [ Yumrepo['centos-base', 'centos-updates'] ]
  }
  service { 'pacemaker':
    ensure => running,
    require => Class['corosync'],
  }

  Service['pacemaker'] -> Cs_location<| |>
  Service['pacemaker'] -> Cs_property<| |>
  Service['pacemaker'] -> Cs_primitive<| |>
  Service['pacemaker'] -> Cs_group<| |>

  service { 'target':
    ensure => running,
    require => Package['targetcli'],
  }
  cs_property { 'stonith-enabled' :
    value   => bool2str($stonith),
  }

  create_resources(iscsirbdha, $targets)
}                           

define iscsirbdha ($vip,
                   $iqn,
                   $path,
                   $monitor_interval = '10s',
                   $iblock = 0,
                   $ensure = 'present') {

  # Break the VIP into its IP address and CIDR netmask
  $viparray = split($vip, '/')
  $ipaddr = $viparray[0]
  $netmask = $viparray[1]

  cs_primitive { "p_vip_${name}":
    primitive_class => 'ocf',
    primitive_type  => 'IPaddr2',
    provided_by     => 'heartbeat',
    parameters      => { 'ip' => $ipaddr, 'cidr_netmask' => $netmask },
    operations      => { 'monitor' => { 'interval' => $monitor_interval } },
    ensure          => $ensure,
  }
  cs_primitive { "p_target_${name}":
    primitive_class => 'ocf',
    primitive_type  => 'iSCSITarget',
    provided_by     => 'heartbeat',
    parameters      => { 'implementation' => 'lio-t', 'iqn' => $iqn },
    operations      => { 'monitor' => { 'interval' => $monitor_interval } },
    require         => Service['target'],
    ensure          => $ensure,
  }
  cs_primitive { "p_lu_${name}":
    primitive_class => 'ocf',
    primitive_type  => 'iSCSILogicalUnit',
    provided_by     => 'heartbeat',
    parameters      => { 'implementation' => 'lio-t', 'target_iqn' => $iqn, 'lun' => 1, 'path' => $path, 'lio_iblock' => $iblock },
    operations      => { 'monitor' => { 'interval' => $monitor_interval } },
    ensure          => $ensure,
  }
  cs_group { "g_${name}":
    primitives      => [ "p_target_${name}",
                         "p_lu_${name}",
                         "p_vip_${name}" ],
    ensure          => $ensure,
  }

}
