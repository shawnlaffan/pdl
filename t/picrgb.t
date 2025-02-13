use strict;
use warnings;
use Test::More;
use PDL::LiteF;
use Test::PDL;
use PDL::IO::Pic;
use PDL::ImageRGB;
use PDL::Dbg;
use File::Temp qw(tempdir);
use File::Spec;

sub rpic_unlink {
  my $file = shift;
  my $pdl = PDL->rpic($file);
  unlink $file;
  return $pdl;
}

sub depends_on {
  note "ushort is ok with $_[0]\n"
	if $PDL::IO::Pic::converter{$_[0]}->{ushortok};
  return 1 if $PDL::IO::Pic::converter{$_[0]}->{ushortok};
  return 256;
}

sub mmax { return $_[0] > $_[1] ? $_[0] : $_[1] }

$PDL::debug = 0;
$PDL::IO::Pic::debug = 0;
my $iform = 'PNMRAW'; # change to PNMASCII to use ASCII PNM intermediate
                      # output format

#              [FORMAT, extension, ushort-divisor,
#               only RGB/no RGB/any (1/-1/0), mxdiff]
#  no test of PCX format because seems to be severely brain damaged
my %formats = ('PNM'  => ['pnm',1,0,0.01],
	       'GIF'  => ['gif',256,0,1.01],
	       'TIFF' => ['tif',1,0,0.01],
	       'RAST' => ['rast',256,0,0.01],
#	       'SGI'  => ['rgb',1,1,0.01],
 	       'PNG'  => ['png',1,1,0.01],
	      );

# only test PNM format
# netpbm has too many bugs on various platforms
my @allowed = ();
## for ('PNM') { push @allowed, $_
for (sort keys %formats) {
   if (PDL->rpiccan($_) && PDL->wpiccan($_) && defined $formats{$_}) {
      push @allowed, $_;
   }
}
plan skip_all => "No tests" if !@allowed;

note "Testable formats on this platform:\n".join(',',@allowed)."\n";

my $im1 = ushort pdl [[[0,0,0],[256,65535,256],[0,0,0]],
		     [[256,256,256],[256,256,256],[256,256,256]],
		     [[2560,65535,2560],[256,2560,2560],[65535,65534,65535]]];
my $im2 = byte ($im1/256);

if ($PDL::debug){
   note $im1;
   note $im2;
}

my $tmpdir = tempdir( CLEANUP => 1 );
sub tmpfile { File::Spec->catfile($tmpdir, $_[0]); }
foreach my $form (sort @allowed) {
    note "** testing $form format **\n";

    my $arr = $formats{$form};
    my $tushort = tmpfile("tushort.$arr->[0]");
    my $tbyte = tmpfile("tbyte.$arr->[0]");
    eval {
        $im1->wpic($tushort,{IFORM => $iform});
    };
    SKIP: {
        my $additional = '';
        if ($@ =~ /maxval is too large/) {
            $additional = ' (recompile pbmplus with PGM_BIGGRAYS!)';
        }
        skip "Error: '$@'$additional", 2 if $@;
        $im2->wpic($tbyte,{IFORM => $iform});

	my $determined_format;
	$determined_format = imageformat($tushort);
	is($determined_format, $form, "image $tushort is format $form");
        my $in1 = rpic_unlink($tushort);

	$determined_format = imageformat($tbyte);
	is($determined_format, $form, "image $tbyte is format $form");
        my $in2 = rpic_unlink($tbyte);

        my $comp = $im1 / PDL::ushort(mmax(depends_on($form),$arr->[1]));
        is_pdl $in1, $comp, {atol=>$arr->[3], test_name=>$form, require_equal_types => 0};
        is_pdl $in2, $im2;

        if ($PDL::debug) {
          note $in1->px;
          note $in2->px;
        }
    }
}

done_testing;
