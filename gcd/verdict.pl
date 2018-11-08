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
use utf8;
use Data::Dumper;

my @courts = ( 'bag', 'bfh', 'bgh', 'bpatg', 'bsg', 'bverfg', 'bverwg' );
my $pos = 0;
my $neg = 0;
my $undetermined = 0;

binmode( STDOUT, "utf8" );
binmode( STDIN,  "utf8" );

# Initialisations

open( my $factsFile, ">:encoding(utf8)", "gcd.facts" )
  || die "Problems opening file gcd.fulltexts: $!\n";
open( my $resultFile, ">:encoding(utf8)", "gcd.results" )
  || die "Problems opening file gcd.types: $!\n";
open( my $factsTestFile, ">:encoding(utf8)", "gcd.facts-test" )
|| die "Problems opening file gcd.fulltexts: $!\n";
open( my $resultTestFile, ">:encoding(utf8)", "gcd.results-test" )
|| die "Problems opening file gcd.types: $!\n";

foreach my $court (@courts) {
    my @documents = glob( $court . '/*' );
    foreach my $document (@documents) {
        if ( $document =~ /xml$/ ) {
            open( my $F, "<:encoding(utf8)", $document )
              || die "Problems opening file $document: $!\n";

            my $content = 0;
            my $flag = 0;
            my $type    = 0;
            my $sentiment = "";
            my $facts    = "";
            my $tenor = "";
            while ( my $line = <$F> ) {
                if ( $line =~ /<doktyp>((.|\n|\r)*)<\/doktyp>/i ) {
                    if ( $1 eq "Urteil") {
                        $type = 1;
                    } else {
                        last; # skip everthing except verdicts
                    }
                }

                # get the tenor
                if ( $line =~ /<tenor>/ ) {
                    $flag = 1;
                }
                if ( $line =~ /<\/tenor>/ ) {
                    $flag = 0;
                }
                if ($flag) {
                    $line =~ s/<.*?>//g;
                    chomp($line);
                    $line =~ s/^\s+//;
                    $line =~ s/\s+$//;
                    if ( !( $line eq '' || $line =~ /^ *$/ ) ) {
                        $tenor .= $line . " ";
                    }
                }


                # get the facts
                if ( $line =~ /<tatbestand>/ ) {
                    #print "tatbestand";
                    $content = 1;
                }
                if ( $line =~ /<\/tatbestand>/ ) {
                    last;
                }
                if ( $content ) {
                    $line =~ s/<.*?>//g;
                    chomp($line);
                    $line =~ s/^\s+//;
                    $line =~ s/\s+$//;
                    if ( !( $line eq '' || $line =~ /^ *$/ ) ) {
                        $facts .= $line . " ";
                    }
                }
            }

            if ($type) {
                if ($tenor =~ /aufgehoben/) {
                    $pos++;
                    $sentiment = "positive";
                } elsif ($tenor =~ /zurückgewiesen/) {
                    $neg++;
                    $sentiment = "negative";
                } elsif ($tenor =~ /verworfen/) {
                    $neg++;
                    $sentiment = "negative";
                } elsif ($tenor =~ /abgewiesen/) {
                    $neg++;
                    $sentiment = "negative";
                } elsif ($tenor =~ /nichtig erklärt/) {
                    $pos++;
                    $sentiment = "positive";
                } elsif ($tenor =~ /aufrechterhalten/) {
                    $neg++;
                    $sentiment = "negative";
                }

                if ( $sentiment eq "positive" ) {
                    if ( !( $facts eq '' || $facts =~ /^ *$/ ) ) {
                        print $facts."\n";
                        print "_______________________________________________________________________\n\n\n\n\n";
                    }
                }
                if ( $sentiment eq "positive" || $sentiment eq "negative" ) {
                    if ( !( $facts eq '' || $facts =~ /^ *$/ ) ) {
                        if (int(rand(100)) <= 1) {
                            #print $factsTestFile $facts . "\n";
                            #print $resultTestFile $sentiment . "\n";
                        } else {
                            #print $factsFile $facts . "\n";
                            #print $resultFile $sentiment . "\n";
                        }
                    } else {
                        $undetermined++;
                    }
                } else {
                }
            }
        }
    }
}
print $neg."\n";
print $pos."\n";
print $undetermined."\n";


close $factsFile;
close $resultFile;
close $factsTestFile;
close $resultTestFile;

__END__
