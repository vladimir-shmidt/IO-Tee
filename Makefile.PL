# -*- perl -*-
require 5.004;
use strict;

require ExtUtils::MakeMaker;

ExtUtils::MakeMaker::WriteMakefile(NAME => 'IO::Tee',
				   VERSION_FROM => 'Tee.pm',
				   'dist' => { 'SUFFIX' => '.gz',
					       'DIST_DEFAULT' => 'all tardist',
					       'COMPRESS' => 'gzip -9f' });

