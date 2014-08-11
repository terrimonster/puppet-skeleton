class profile::puppet::master::r10k (
  $control_repo,
  $mco_enable = '',
  $webhook = '',
  $git_server = '',
) {
  validate_string($control_repo)
  validate_bool($mco_enable)

  class { '::r10k': remote => $control_repo, }
  include ::git
  if $mco_enable == true {
    include ::r10k::mcollective
  }

  if $webhook == true {
    class { 'r10k::webhook':
      git_server => $git_server,
    }

    class {'r10k::webhook::config':
      prefix         => false,
      enable_ssl     => false,
      protected      => false,
      notify         => Service['webhook'],
    }
  }
}
