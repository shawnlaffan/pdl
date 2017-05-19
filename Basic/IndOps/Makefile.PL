use ExtUtils::MakeMaker;

$package = ["indxxx.pd",qw(IndOps PDL::IndOps)];
%hash = pdlpp_stdargs_int($package);
$hash{'VERSION_FROM'} = 'indxxx.pd';
WriteMakefile(%hash);

sub MY::postamble { pdlpp_postamble_int($package); }

