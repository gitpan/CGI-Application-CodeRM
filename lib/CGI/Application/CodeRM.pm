package CGI::Application::CodeRM ;
$VERSION = 0.01 ;

; use strict
; use Carp qw| croak carp |
; use CGI::Application
; our $CGIAPPVERS = 3.1

; sub import
   { my ($pkg, $force) = @_
   ; $force &&= $force eq '-force'
   ; unless ( $force )
      { croak   'This module works only with CGI::Application Version 3.1, '
              . 'please update it.'
              unless $CGI::Application::VERSION == $CGIAPPVERS
      }
   ; no strict 'refs'
   ; local $SIG{__WARN__} = sub { &Carp::carp }
   ; my $callpkg = (caller)[0]
   ; *{"$callpkg\::run"} = \&{"$pkg\::run"}
   }

sub run {
	my $self = shift;
	my $q = $self->query();

	my $rm_param = $self->mode_param() || croak("No rm_param() specified");

	my $rm;

	# Support call-back instead of CGI mode param
	if (ref($rm_param) eq 'CODE') {
		# Get run-mode from subref
		$rm = $rm_param->($self);
	} else {
		# Get run-mode from CGI param
		$rm = $q->param($rm_param);
	}

	# If $rm undefined, use default (start) mode
	my $def_rm = $self->start_mode() || '';
	$rm = $def_rm unless (defined($rm) && length($rm));

	# Set get_current_runmode() for access by user later
	$self->{__CURRENT_RUNMODE} = $rm;

	# Allow prerun_mode to be changed
	delete($self->{__PRERUN_MODE_LOCKED});

	# Call PRE-RUN hook, now that we know the run-mode
	# This hook can be used to provide run-mode specific behaviors
	# before the run-mode actually runs.
	$self->cgiapp_prerun($rm);

	# Lock prerun_mode from being changed after cgiapp_prerun()
	$self->{__PRERUN_MODE_LOCKED} = 1;

	# If prerun_mode has been set, use it!
	my $prerun_mode = $self->prerun_mode();
	if (length($prerun_mode)) {
		carp ("Replacing previous run-mode '$rm' with prerun_mode '$prerun_mode'") if ($^W);
		$rm = $prerun_mode;
		$self->{__CURRENT_RUNMODE} = $rm;
	}

	my %rmodes = ($self->run_modes());

	my $rmeth;
	my $autoload_mode = 0;
	if (exists($rmodes{$rm})) {
		$rmeth = $rmodes{$rm};
	} else {
		# Look for run-mode "AUTOLOAD" before dieing
		unless (exists($rmodes{'AUTOLOAD'})) {
			croak("No such run-mode '$rm'");
		}
		carp ("No such run-mode '$rm'.  Using run-mode 'AUTOLOAD'") if ($^W);
		$rmeth = $rmodes{'AUTOLOAD'};
		$autoload_mode = 1;
	}

	# Process run mode!
        my $body = eval { $autoload_mode ? $self->$rmeth($rm) : $self->$rmeth() };
        die "Error executing run mode '$rm': $@" if $@;

###### ORIGINAL ##########

#        # Support scalar-ref for body return
#        my $bodyref = (ref($body) eq 'SCALAR') ? $body : \$body;

#        # Call cgiapp_postrun() hook
#        $self->cgiapp_postrun($bodyref);

#  # Set up HTTP headers
#  my $headers = $self->_send_headers();

#  # Build up total output
#  my $output = $headers . $$bodyref;

#  # Send output to browser (unless we're in serious debug mode!)
#  unless ($ENV{CGI_APP_RETURN_ONLY}) {
#    print $output;
#  }

#  # clean up operations
#  $self->teardown();

#  return $output;

###### HACKED ##########

        my $is_sub = ref($body) eq 'CODE';
        
        # support all returned references
        my $bodyref = (ref($body) eq 'SCALAR' || $is_sub) ? $body : \$body;
        
        
        # Call cgiapp_postrun() hook
        $self->cgiapp_postrun($bodyref) unless $is_sub ;

	# Set up HTTP headers
	my $headers = $self->_send_headers();

	# Build up total output
 	my $output = $headers . $$bodyref unless $is_sub;
 

	# Send output to browser (unless we're in serious debug mode!)
	unless ($ENV{CGI_APP_RETURN_ONLY})
	{
    if ($is_sub) {  print $headers  ;
                    &$bodyref       }
    else         {  print $output   }
	}

	# clean up operations
	$self->teardown();

	if ($is_sub)
	{
	  if ($ENV{CGI_APP_RETURN_ONLY}) { return &$bodyref }
	  else { return 1 }
	}
	else { return $output }
	  
###### END HACK ##########

}

1 ;

__END__

=head1 NAME

CGI::Application::CodeRM - handles CODE references returned from Run Modes

=head1 VERSION 0.01

This version works for sure with CGI::APPLICATION 3.1 ONLY, while with other versions it may or may not work. Please update it if needed.

=head1 SYNOPSIS

     # in Application module
     
     # as usual
     use base CGI::Application ;
     
     # croak if not correct version (if it don't croak it works for sure)
     use CGI::Application::CodeRM ;
     
     # does not croak (may be it works however)
     use CGI::Application::CodeRM qw(-force);

=head1 DESCRIPTION

This module adds a possibility to the plain CGI::Application module: instead of returning the output itself, a run mode can return a code reference that will print the output on its own. The refereced code will be called after the printing of the headers.

The main advantage is that you can avoid to charge the memory with the whole (and sometime huge) output and print it while it is produced.

This is particularly useful if you are using HTML::MagicTemplate, that can print with minimum memory requirements, but you can also use it with your own subroutines.

B<Warning>: For obvious reasons, if your RM returns a code reference, the cgiapp_postrun() method will not be called even if defined (see cgiapp_postrun() in L<CGI::Application> for details). In the case you have defined a cgiapp_postrun() method, your referenced code should handle this situation on its own.

=head2 How it works

This module override the CGI::Application run() method with its own (hacked) method. For this reason it works for sure ONLY with a specific CGI::Application version, but it may work anyway with other versions that implement the same run() method. You can force the import of the hacked method even if you use a different CGI::Application version if you use the C<-force> directive at import (see L<"SYNOPSIS">).

=head1 HTML::MagicTemplate hints

The following example uses the C<output()> method that returns a reference to the template output, thus collecting the output in memory until printed by the CGI::Application module.

    sub a_run_mode
    {
      ....
      return $mt->output('/path/to/template')
    }

The following example, instead, uses the C<print()> method that is more memory efficient, because it prints the output during the process.

    sub a_run_mode
    {
      ....
      return sub{ $mt->print('/path/to/template') }
    }

=head1 INSTALLATION

=over

=item Prerequisites

    Perl version >= 5.005

=item CPAN

    perl -MCPAN -e 'install CGI::Application::CodeRM'

=item Standard installation

From the directory where this file is located, type:

    perl Makefile.PL
    make
    make test
    make install

=back

=head1 SEE ALSO

=over

=item * L<HTML::MagicTemplate|HTML::MagicTemplate>

=item * L<Text::MagicTemplate|Text::MagicTemplate>

=back

=head1 SUPPORT and FEEDBACK

I would like to have just a line of feedback from everybody who tries or actually uses this module. PLEASE, write me any comment, suggestion or request. ;-)

More information about other modules at http://perl.4pro.net/?CGI::Application::CodeRM.

=head1 AUTHOR

Domizio Demichelis, <dd@4pro.net>.

=head1 COPYRIGHT

Copyright (c)2002 Domizio Demichelis. All Rights Reserved. This is free software; it may be used freely and redistributed for free providing this copyright header remains part of the software. You may not charge for the redistribution of this software. Selling this code without Domizio Demichelis' written permission is expressly forbidden.

This software may not be modified without first notifying the author (this is to enable me to track modifications). In all cases the copyright header should remain fully intact in all modifications.

This code is provided on an "As Is'' basis, without warranty, expressed or implied. The author disclaims all warranties with regard to this software, including all implied warranties of merchantability and fitness, in no event shall the author, be liable for any special, indirect or consequential damages or any damages whatsoever including but not limited to loss of use, data or profits. By using this software you agree to indemnify the author from any liability that might arise from it is use. Should this code prove defective, you assume the cost of any and all necessary repairs, servicing, correction and any other costs arising directly or indrectly from it is use.

The copyright notice must remain fully intact at all times. Use of this software or its output, constitutes acceptance of these terms.

=head1 BUGS

First release not very tested yet, but since it does a VERY simple thing, it has very little possibility to fail ;-).










































































































































































































































































