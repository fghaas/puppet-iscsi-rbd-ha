node puppetmaster {
  include puppetmaster
}

node /^ceph\d+$/ {
  include ceph::profile::mon
  include ceph::profile::osd
}

node /^iscsi\d+$/ {
  include iscsirbdha
}

class puppetmaster {
  service { 'puppetmaster':
    ensure => 'running',
  }
}

