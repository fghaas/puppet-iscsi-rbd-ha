node puppetmaster {
  service { 'puppetmaster':
    ensure => 'running',
  }
}
node /^iscsi\d+$/ {
  tidy { '/etc/yum.repos.d':
    matches => ['CentOS-*.repo'],
    recurse => true,
  }
  yumrepo { 'centos-base':
    mirrorlist => 'http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=os&infra=$infra',
    # baseurl => 'http://mirror.centos.org/centos/$releasever/os/$basearch/',
    gpgcheck => 1,
    gpgkey => 'file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7',
    exclude => 'ceph* python-rados* python-rbd* python-cephfs* python-ceph-compat* libcephfs* librados2* librbd1',
    require => Tidy['/etc/yum.repos.d'],
  }
  yumrepo { 'centos-updates':
    mirrorlist => 'http://mirrorlist.centos.org/?release=$releasever&arch=$basearch&repo=updates&infra=$infra',
    # baseurl=http://mirror.centos.org/centos/$releasever/updates/$basearch/,
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
  class { 'corosync':
    enable_secauth    => true,
    authkey_source    => 'string',
    authkey           => 'ahNeiteizohSeiGhoh6reene9Zeinge1chie1Sienee0Ohpoociehai1ohcaemai3eiz3eG7zebeeB7eimai6ooR4toot4eeth6ohv2eiQu1Aegh5bei7xoh3roo7ooz',
    multicast_address => '239.255.1.0',
    quorum_members    => ['192.168.122.190', '192.168.122.173'],
    require => [ Yumrepo['centos-base', 'centos-updates'] ]
  }
  service { 'pacemaker':
    ensure => running,
    require => Class['corosync'],
    require => [ Yumrepo['centos-base', 'centos-updates'] ]
  }
  cs_property { 'stonith-enabled' :
    value   => 'false',
    require => Service['pacemaker'],
  }
  cs_primitive { 'p_vip':
    primitive_class => 'ocf',
    primitive_type  => 'IPaddr2',
    provided_by     => 'heartbeat',
    parameters      => { 'ip' => '192.168.122.170', 'cidr_netmask' => '24' },
    operations      => { 'monitor' => { 'interval' => '10s' } },
    require => Service['pacemaker'],
  }
}
