use strict;
use warnings;
use 5.010;

use Module::Build;

Module::Build->new(
  module_name   => 'Term::Sk',
  license       => 'perl',
  dist_abstract => 'Perl extension for displaying a progress indicator on a terminal',
)->create_build_script;
