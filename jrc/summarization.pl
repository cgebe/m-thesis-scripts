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

my %options = (
    'acquisDir' => 'acquis/',
    'alignDir'  => 'align/*',
    'outDir'    => 'out/',
);

my @languages = ( 'cs', 'de', 'en', 'es', 'fr', 'it', 'sv' );
#my @languages = ('de');

binmode( STDOUT, "utf8" );
binmode( STDIN,  "utf8" );

# Initialisations

my %text = ();

my %celexCodes;
my $select  = 0;
my $sizesel = 0;

# create tesdoc map
open( my $testInfo, "<:encoding(utf8)", "test-summary.info" )
  || die "Problems opening file test.info: $!\n";

my %testDocs;
while ( my $line = <$testInfo> ) {
    chomp $line;
    $testDocs{$line} = 1;
}

foreach my $lang (@languages) {
    my $testdoc = 0;
    my $doc     = 0;
    my $skipped = 0;
    open( my $summaries,
        ">:encoding(utf8)",
        "out/summarization/jrc_acquis." . $lang . ".summaries" )
      || die "Problems opening file summaries out: $!\n";
    open( my $fulltexts,
        ">:encoding(utf8)",
        "out/summarization/jrc_acquis." . $lang . ".fulltexts" )
      || die "Problems opening file fulltexts out: $!\n";
    open( my $docinfo, ">:encoding(utf8)",
        "out/summarization/jrc_acquis." . $lang . ".info" )
      || die "Problems opening file doc info out: $!\n";
    open( my $testsummaries,
        ">:encoding(utf8)",
        "out/summarization/jrc_acquis." . $lang . "-test.summaries" )
      || die "Problems opening file summaries out: $!\n";
    open( my $testfulltexts,
        ">:encoding(utf8)",
        "out/summarization/jrc_acquis." . $lang . "-test.fulltexts" )
      || die "Problems opening file fulltexts out: $!\n";
    open( my $testdocinfo,
        ">:encoding(utf8)",
        "out/summarization/jrc_acquis." . $lang . "-test.info" )
      || die "Problems opening file doc info out: $!\n";
      open( my $skipinfo,
          ">:encoding(utf8)",
          "out/summarization/jrc_acquis." . $lang . "-skip.info" )
        || die "Problems opening file doc info out: $!\n";

    my @yearFolders = grep { -d } glob 'acquis/' . $lang . '/*';
    foreach my $yearFolder (@yearFolders) {
        my @documents = glob( $yearFolder . '/*' );
        foreach my $document (@documents) {
            my @paragraphs = &loadParagraphs($document);
            my $summary    = shift @paragraphs;
            my $start = 0;   # do not add the first paragraph ever, same as head
            my $fulltext = "";
            my $acc     = "";
            my $maxParagraphs = 0;
            foreach my $paragraph (@paragraphs) {
                if ($start) {
                    $fulltext .= $paragraph . " ";
                } else {
                    $acc .= ' ' . $paragraph;
                    my $similarity = compare($summary, $acc);
                    if ($similarity >= 0.5) {
                        $start = 1;
                    }
                    if ($maxParagraphs >= 6) {
                        last;
                    }
                    $maxParagraphs++;
                }
            }
            if ($start == 0) {
                print $skipinfo $document . "\n";
                $skipped++;
            } else {
                my $id = ( split( "-", ( ( split( "/", $document ) )[3] ) ) )[0];
                if ( $testDocs{$id} ) {

                    # test doc
                    print $testsummaries $summary . "\n";
                    print $testfulltexts $fulltext . "\n";
                    print $testdocinfo $id . "\n";
                    $testdoc++;
                }
                else {
                    print $summaries $summary . "\n";
                    print $fulltexts $fulltext . "\n";
                    print $docinfo $id . "\n";
                    $doc++;
                }
            }
        }
    }
    print $lang. " documents: " . $doc . " test documents: " . $testdoc . " skipped: " . $skipped. "\n";
    close($summaries);
    close($fulltexts);
    close($docinfo);
    close($testsummaries);
    close($testfulltexts);
    close($testdocinfo);
    close($skipinfo);
}

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
