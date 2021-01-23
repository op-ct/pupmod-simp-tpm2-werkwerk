# @summary Provides the ability to set or clear the authentication passwords for the TPM
#
# At this time you can clear a set password but cannot change it to another value.
#
# To use this module, set tpm2::take_ownership to true in hiera
# and set the parameters in hiera to override the defaults.
#
# @param owner
#   The desired state of the owner authentication.
#   If tpm2-tools < 4.0.0 is installed you can not use the
#   'ignore' option.  It attempts to set all 3.
#   Puppet will display a warning and not attempt to set
#   auth value if it is used and the earlier version of
#   tpm tools is set.
#
# @param endorsement
#   The desired state of the endorsement authentication.
#   See owner param for more information.
#
# @param lockout
#   The desired state of the lockout authentication.
#   See owner param for more information.
#
# @param owner_auth
#   The password word for owner authentication.
#
# @param lockout_auth
#   The password word for lockout authentication.
#
# @param endorsement_auth
#   The password word for endorsement authentication.
#
# @param in_hex
#   Whether or not the passwords are in Hex.
#   This value is ignore if tpm2_tools package > 4.0.0
#   is installed.
#
# @example
#
#  In Hiera set the following:
#    tpm2::take_ownership: true
#    tpm2::ownership::owner: set
#    tpm2::ownership::lockout:  clear
#    tpm2::ownership::endorsement: set
#
# The passwords will default to automatically generated passwords using simplib::passgen.  If
# you want to set them to specific passwords then set them in hiera using the
# following settings (it expects a minumum password length of 14 charaters):
#
#   tpm2::ownership::owner_auth: 'MyOwnerPassword'
#   tpm2::ownership::lockout_auth:  'MyLockPassword'
#   tpm2::ownership::endorsement_auth: 'MyEndorsePassword'
#
# @author SIMP Team https://simp-project.com
#
class tpm2::ownership(
  Enum['set','clear','ignore']   $owner              = 'clear',
  Enum['set','clear','ignore']   $endorsement        = 'clear',
  Enum['set','clear','ignore']   $lockout            = 'clear',
  String[14]                     $owner_auth         = simplib::passgen("${facts['fqdn']}_tpm_owner_auth", {'length'=> 24}),
  String[14]                     $lockout_auth       = simplib::passgen("${facts['fqdn']}_tpm_lock_auth", {'length'=> 24}),
  String[14]                     $endorsement_auth   = simplib::passgen("${facts['fqdn']}_tpm_endorse_auth", {'length'=> 24}),
  Boolean                        $in_hex             = false
){

  if $facts['tpm2'] and $facts['tpm2']['tools_version'] {
    if  versioncmp($facts['tpm2']['tools_version'], '4.0.0') < 0 {

      if $owner == 'ignore' or $endorsement == 'ignore' or $lockout == 'ignore' {
        fail("$modulename : 'ignore' is not a valid setting for param owner, endorsement or lockout when tpm2-tools verions < 4.0.0 is installed. Current version is ${facts['tpm2']['tools_version']}")
      } else {
        tpm2_ownership { 'tpm2':
          owner            => $owner,
          lockout          => $lockout,
          endorsement      => $endorsement,
          owner_auth       => $owner_auth,
          endorsement_auth => $endorsement_auth,
          lockout_auth     => $lockout_auth,
          in_hex           => $in_hex,
          require          => Class['tpm2::service']
        }
      }
    } else {
    # tpm2-tools version >= 4.0.0
      unless $owner == 'ignore' {
        tpm2_changeauth { 'owner':
          auth    => $owner_auth,
          state   => $owner,
          require => Class['tpm2::service']
        }
      }
      unless $lockout == 'ignore' {
        tpm2_changeauth { 'lockout':
          auth    => $lockout_auth,
          state   => $lockout,
          require => Class['tpm2::service']
        }
      }
      unless $endorement == 'ignore' {
        tpm2_changeauth { 'endorement':
          auth    => $endorement_auth ,
          state   => $endorement,
          require => Class['tpm2::service']
        }
      }
    }
  }

}
