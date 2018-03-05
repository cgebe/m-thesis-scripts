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

my @languages = ( 'de', 'en', 'es', 'fr', 'it', 'sv' );

binmode( STDOUT, "utf8" );
binmode( STDIN,  "utf8" );

# Initialisations

my %text = ();

my %celexCodes;
my $select  = 0;
my $sizesel = 0;

# create tesdoc map
open( my $testInfo, "<:encoding(utf8)", "test.info" )
  || die "Problems opening file test.info: $!\n";

my %testDocs;
while ( my $line = <$testInfo> ) {
    chomp $line;
    $testDocs{$line} = 1;
}

foreach my $lang (@languages) {
    my $doc = 0;
    open( my $summaries, ">:encoding(utf8)", "out/summarization/jrc_acquis.".$lang.".summaries" )
      || die "Problems opening file summaries out: $!\n";
    open( my $fulltexts, ">:encoding(utf8)", "out/summarization/jrc_acquis.".$lang.".fulltexts" )
      || die "Problems opening file fulltexts out: $!\n";
    open( my $docinfo, ">:encoding(utf8)", "out/summarization/jrc_acquis.".$lang.".info" )
      || die "Problems opening file doc info out: $!\n";

    my @yearFolders = grep { -d } glob 'acquis/' . $lang . '/*';
    foreach my $yearFolder (@yearFolders) {
        my @documents = glob( $yearFolder . '/*' );
        foreach my $document (@documents) {
            my @paragraphs = &loadParagraphs($document);
            my $summary = shift @paragraphs;
            my $fulltext = "";
            foreach my $paragraph (@paragraphs) {
                $fulltext .= $paragraph . " ";
            }
            print $summaries $summary."\n";
            print $fulltexts $fulltext."\n";
            print $docinfo $document."\n";
            $doc++;
        }
    }
    print $lang." documents: " . $doc;
    close($summaries);
    close($fulltexts);
    close($docinfo);
}

sub loadTestInfo {
    my ( $lg1, $lg2 ) = @_;
    my %testInfo;
    my $testFile = "ac-test.info";

    open( my $F, "<:encoding(utf8)", $testFile )
      || do { warn "No test file found, continue"; return (); };
    while ( my $line = <$F> ) {
        my ( $docid, $remains ) =
          split( /\s/, $line, 2 );  # 0: docid | 1: bg:5,cs:4,da:5,de:5,el:3,...
        $remains =~ s/\s+$//;       #  remove trailing spaces
        my @samples = split( /,/, $remains )
          ;    # 0: bg:5 | 1: cs:4 | 2: da:5 | 3: de:5 | 4: el:3,...
        if ( !$testInfo{$docid} ) {
            $testInfo{$docid} = {};
        }

        # init hack
        foreach my $sample (@samples) {
            my @spec = split( /:/, $sample );    # 0: bg | 1: 5
            if ( ( $lg1 eq $spec[0] || $lg2 eq $spec[0] )
                && !$testInfo{$docid}->{ $spec[0] } )
            {
                $testInfo{$docid}->{ $spec[0] } = [];
            }
        }

        foreach my $sample (@samples) {
            my @spec = split( /:/, $sample );    # 0: bg | 1: 5
            if ( $lg1 eq $spec[0] || $lg2 eq $spec[0] ) {
                push $testInfo{$docid}->{ $spec[0] }, $spec[1];
            }
        }
    }
    close $F;
    return %testInfo;
}

sub loadParagraphs {
    my ( $file ) = @_;
    my @paragraphs = ();

    open( my $F, "<:encoding(utf8)", $file )
      || die "Problems opening file $file: $!\n";
    while ( my $line = <$F> ) {
        if ( $line =~ /<head n=\"([^\"]+)\">((.|\n|\r)*)<\/head>/i ) {
            #print  $1,"\t", $2,"\n";
            push @paragraphs, $2; # push head onto paragraphs
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

sub getSentence {
    my ( $lg, $targets1 ) = @_;
    my $line = "";
    my @targets1 = split( /[\s]+/, $targets1 );

    # discard insert or deletetion
    if ( scalar @targets1 > 0 ) {
        foreach my $t (@targets1) {
            $line .= $text{$lg}->{s}->[$t] . " ";
        }
        $line =~ s/[\s]+$//;
    }
    return $line;
}

__END__
