use ExtUtils::MakeMaker;

WriteMakefile
(
  NAME             => 'CGI::Application::CodeRM',
  VERSION_FROM     => 'lib/CGI/Application/CodeRM.pm',
  ($] ge '5.005')
     ? ('AUTHOR'   => 'Domizio Demichelis <dd\@4pro.net>',
        'ABSTRACT' => 'Magic merger of runtime values with templates' )
     : (),
);

