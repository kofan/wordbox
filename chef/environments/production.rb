# Author: Nickolay U. Kofanov
# Date: 2015-02-27

name "production"
description "Production environment"

override_attributes(
  :wpbx => {
    :debug_mode => false,
  },
  :php => {
    :directives => {
      :display_errors => '0',
      :display_startup_errors => '0',
      :error_reporting => 'E_ALL & ~E_DEPRECATED'
    }
  }
)