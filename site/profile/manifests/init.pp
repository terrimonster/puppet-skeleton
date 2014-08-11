#Profile classes are wrapper classes that
#implement component classes from the Forge
class profile (
  $myvar = $::profile::params::myvar
) inherits profile::params {
  notify{"Myvar is ${myvar}": }

}
