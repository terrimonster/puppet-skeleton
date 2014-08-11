class profile::puppet::master::params {
  $modulepath = "${::settings::confdir}/puppet/modules"
  $manifest = "${::settings::confdir}/puppet/manifests/site.pp"
  $environments_dir = "${::settings::confdir}/puppet/environments"
  $hiera_config_file = "${::settings::confdir}/puppet/hiera.yaml"
  $hiera_backends = ['yaml']
}
