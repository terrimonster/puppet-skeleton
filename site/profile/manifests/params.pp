class profile::params {
  case $::operatingsystem {
    'CentOS':{
      notify{"CentOS is supported":}
      $myvar = "This is a CentOS system"
    }
    'Ubuntu':{
      notify{"CentOS is supported":}
      $myvar = "This is an Ubuntu system"
    }
    default:{
      fail("OS ${::operatingsystem} is not supported.")
    }
  }
}
