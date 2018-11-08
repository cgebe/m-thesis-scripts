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

my %types = ();
my $count = 0;
my $a = 0;

foreach my $court (@courts) {
    print $court."\n";
    %types = ();
    $count = 0;
    my @documents = glob( $court . '/*' );
    foreach my $document (@documents) {
        if ($document =~ /xml$/) {
            $count++;
            $a++;
            open( my $F, "<:encoding(utf8)", $document )
              || die "Problems opening file $document: $!\n";
              my $verdict = 0;
            while ( my $line = <$F> ) {
                if ( $line =~ /<doktyp>((.|\n|\r)*)<\/doktyp>/i ) {
                    $types{$1}++
                }
            }
        }
    }
    print Dumper(\%types);
    print $count."\n";
}
print $a;


sub loadParagraphs {
    my ($file) = @_;
    my @paragraphs = ();

    open( my $F, "<:encoding(utf8)", $file )
      || die "Problems opening file $file: $!\n";
    while ( my $line = <$F> ) {
        if ( $line =~ /<head n=\"([^\"]+)\">((.|\n|\r)*)<\/head>/i ) {

            #print  $1,"\t", $2,"\n";
            push @paragraphs, $2;    # push head onto paragraphs
        }

        # print "LINE:",$line;
        if ( $line =~ /<p n=\"([^\"]+)\">((.|\n|\r)*)<\/p>/i ) {

            #print  $1,"\t", $2,"\n";
            push @paragraphs, $2;
        }
    }
    close $F;
    return @paragraphs;
}

sub compare {
    my ( $str1, $str2 ) = @_;
    my $tok_str1 = tokenize($str1);
    my $tok_str2 = tokenize($str2);

    # make a lookup hash for the smaller numer of tokens in str2
    my %h;
    @h{@$tok_str2} = ();    # slice syntax if fastest
                            # now scan str1 for these tokens and count
    my $found = 0;
    for my $tok (@$tok_str1) {
        $found++ if exists $h{$tok};
    }
    my $similarity = $found / @$tok_str1;
    return $similarity;
}

sub tokenize {
    my ($str) = @_;

    # remove punctuation stuff
    $str =~ s/[^A-Za-z0-9 ]+//g;

    # lowercase
    $str = lc $str;

    # magic whitespace split and return array ref
    return [ split ' ', $str ];
}

__END__
