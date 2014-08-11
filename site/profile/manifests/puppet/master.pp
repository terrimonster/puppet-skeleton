class profile::puppet::master (
  $modulepath          =  $::profile::puppet::master::params::modulepath,
  $manifest            =  $::profile::puppet::master::params::manifest,
  $environments_dir    =  $::profile::puppet::master::params::environments_dir,
  $hiera_hierarchy     =  [],
  $hiera_backends      =  ['yaml'],
  $hiera_extra_config  =  '',
  $r10k_enable         =  false,
  $r10k_mco_enable     =  false,
  $r10k_control_repo   =  '',
  $enable_eyaml        = false,
  $eyaml_keydir        = '/etc/puppetlabs/puppet/keys'
  $tagmail             = false,
  $tagmail_email       = 'test@example.com',
) inherits ::profile::puppet::master::params {

  validate_string($modulepath, $manifest, $hiera_extra_config,$r10k_control_repo)
  validate_string($environments_dir)
  validate_array($hiera_backends, $hiera_hierarchy)
  validate_bool($r10k_enable)

  require ::gcc

  if $enable_eyaml {
    package { 'hiera-eyaml':
      ensure => installed,
      provider => 'pe_gem',
    }

    file { 'eyaml-keys':
      ensure => directory,
      path => $eyaml_keydir,
      mode => '0604',
      owner => 'pe-puppet',
      group => 'pe-puppet',
      require => Exec['createkeys'],
    }

    exec { 'createkeys':
      user    => 'pe-puppet',
      cwd => '/etc/puppetlabs/puppet',
      command => '/opt/puppet/bin/eyaml createkeys',
      path => '/opt/puppet/bin',
      creates => "${eyaml_keydir}/private_key.pkcs7.pem",
      require => Package['hiera-eyaml'],
    }
    $eyaml_files = ["${eyaml_keydir}/private_key.pkcs7.pem,"${eyaml_keydir}/public_key.pkcs7.pem"]

    file { $eyaml_files:
      ensure => file,
      mode => '0604',
      owner => 'pe-puppet',
      group => 'pe-puppet',
      require => Exec['createkeys'],
    }
  }
  class { 'hiera':
    hierarchy => $hiera_hierarchy,
    backends => $hiera_backends,
    extra_config => $hiera_extra_config ? { '' => undef, default => $hiera_extra_config },
    datadir => '"/etc/puppetlabs/puppet/environments/%{::environment}/data"',
  }

  service { 'pe-httpd':
    ensure => running,
    enable => true,
  }

  ini_setting { 'PE module path':
    ensure => present,
    path => "${::settings::confdir}/puppet.conf",
    section => 'main',
    setting => 'environmentpath',
    value => '$confdir/environments',
    notify => Service['pe-httpd'],
  }

  ini_setting { 'PE master autosign':
    ensure => present,
    path => "${::settings::confdir}/puppet.conf",
    section => 'master',
    setting => 'autosign',
    value => 'true',
    notify => Service['pe-httpd'],
  }

  if $tagmail {
    ini_setting { 'PE master reports':
      ensure => present,
      path => "${::settings::confdir}/puppet.conf",
      section => 'master',
      setting => 'reports',
      #value => 'console,puppetdb,tagmail',
      value => 'console,puppetdb',
      notify => Service['pe-httpd'],
    }

    file { 'PE tagmail config':
      ensure => file,
      path => "${::settings::confdir}/tagmail.conf",
      content => "err, emerg, crit: ${tagmail_email}",
    }
  }
  Service <| title == 'pe-httpd' |> {
    subscribe +> Class['hiera'],
  }

  file { 'PE enviornments directory':
    ensure => directory,
    path => "${::settings::confdir}/environments",
  }

  if $r10k_enable {
    class { '::profile::puppet::master::r10k':
      control_repo => $r10k_control_repo,
      control_repo_deploy_key => $r10k_control_repo_deploy_key,
      control_repo_deploy_pub_key => $r10k_control_repo_deploy_pub_key,
      mco_enable => $r10k_mco_enable,
    }
  }

  file { 'mco symlink':
    ensure => link,
    path => '/usr/local/bin/mco',
    target => '/opt/puppet/bin/mco',
  }
}
