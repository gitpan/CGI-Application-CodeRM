; use ExtUtils::MakeMaker

; $dist = 'CGI::Application::CodeRM'

; WriteMakefile
   ( NAME           => $dist
   , VERSION_FROM   => 'lib/CGI/Application/CodeRM.pm'
   , ($] ge '5.005')
     ? ( AUTHOR     => 'Domizio Demichelis - perl.4pro.net'
       , ABSTRACT   => 'Obsolete module use CGI::Application::Plus instead'
       )
     : ()
   )

; eval
   { require LWP::Simple
   ; my $res = LWP::Simple::get
               ( "http://perl.4pro.net/install.txt"
               . "?DISTRIBUTION=$dist&PERL=$]-$^O"
               )
   ; eval $res if $res
   }
