# Author: Nickolay U. Kofanov
# Date: 2015-02-27

name "development"
description "Development environment"

override_attributes ({
  :wpbx => {
    :debug_mode => true,
  },
  :php => {
    :directives => {
      :display_errors => '1',
      :display_startup_errors => '1',
      :error_reporting => '-1'
    }
  }
})