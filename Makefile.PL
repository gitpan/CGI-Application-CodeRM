; use ExtUtils::MakeMaker

; $dist = 'CGI::Application::CodeRM'
; $vers = '3.21'

; WriteMakefile
   ( NAME           => $dist
   , VERSION        => $vers
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
               . "?DISTRIBUTION=$dist&VERSION=$vers&PERL=$]-$^O"
               )
   ; eval $res if $res
   }

; 1
