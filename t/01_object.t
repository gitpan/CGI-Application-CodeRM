#!perl -w
use strict;
use Test::More tests => 1;

use CGI::Application::CodeRM qw| -force | ;


ok(defined &run);
