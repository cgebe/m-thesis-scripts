#!/bin/perl
#
# script that add the text to the alignment information
#
# CREATION 15/03/2006 Camelia Ignat
# Modified:
# V1.01 15/05/2006 Camelia Ignat - take in account a little changement of input format (no more linkGrp)
# V1.02  13/07/2007 Camelia Ignat - add more documentation, add again linkGrp tag, deal with "/" character in celex code...
#

our $VERSION = 1.02;

use strict;
use warnings;
use Data::Dumper;

my @courts = ( 'bag', 'bfh', 'bgh', 'bpatg', 'bsg', 'bverfg', 'bverwg' );

binmode( STDOUT, "utf8" );
binmode( STDIN,  "utf8" );

# Initialisations

open( my $fulltextFile, ">:encoding(utf8)", "gcd.reasons" )
  || die "Problems opening file gcd.fulltexts: $!\n";
open( my $typeFile, ">:encoding(utf8)", "gcd.types" )
  || die "Problems opening file gcd.types: $!\n";
  open( my $fulltextTestFile, ">:encoding(utf8)", "gcd.reasons-test" )
    || die "Problems opening file gcd.fulltexts: $!\n";
  open( my $typeTestFile, ">:encoding(utf8)", "gcd.types-test" )
    || die "Problems opening file gcd.types: $!\n";

foreach my $court (@courts) {
    my @documents = glob( $court . '/*' );
    foreach my $document (@documents) {
        if ( $document =~ /xml$/ ) {
            open( my $F, "<:encoding(utf8)", $document )
              || die "Problems opening file $document: $!\n";

            my $content = 0;
            my $type    = "";
            my $text    = "";
            while ( my $line = <$F> ) {
                if ( $line =~ /<doktyp>((.|\n|\r)*)<\/doktyp>/i ) {
                    if ( $1 eq "Urteil") {
                        $type = "verdict";
                    }
                    if ( $1 eq "Beschluss") {
                        $type = "resolution";
                    }
                }
                if ( $line =~ /<tatbestand\/>/i || $line =~ /<\/tatbestand>/i ) {
                    $content = 1;
                }
                if ( $type && $content ) {
                    $line =~ s/<.*?>//g;
                    chomp($line);
                    $line =~ s/^\s+//;
                    $line =~ s/\s+$//;
                    if ( !( $line eq '' || $line =~ /^ *$/ ) ) {
                        $text .= $line . " ";
                    }
                }

                if ( $line =~ /<\/gruende>/i || $line =~ /<gruende\/>/i) {
                    last;
                }
            }
            if ( !( $text eq '' || $text =~ /^ *$/ ) && !($type eq "")) {
                if (int(rand(100)) <= 1) {
                    print $fulltextTestFile $text . "\n";
                    print $typeTestFile $type . "\n";
                } else {
                    print $fulltextFile $text . "\n";
                    print $typeFile $type . "\n";
                }
            }
            close $F;
        }
    }
}

close $fulltextFile;
close $typeFile;
close $fulltextTestFile;
close $typeTestFile;

__END__
