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

binmode( STDOUT, "utf8" );
binmode( STDIN,  "utf8" );

# Initialisations

my %text = ();

my %celexCodes;
my $select  = 0;
my $sizesel = 0;

my @acquis = <$options{acquisDir}>;
my @aligns = <$options{alignDir}>;


# iterate alignment files
foreach my $alignFile (@aligns) {
    my @names = split( /\./, $alignFile );
    my @trans = split( '-',  $names[0] );    # get language pair
    my $langDir1 = $options{acquisDir} . $trans[1];
    my $langDir2 = $options{acquisDir} . $trans[2];
    my $celexcode;
    my $docid1;
    my $docid2;
    my $outFilelg1 =
        $options{'outDir'}
      . "/jrc_acquis."
      . $trans[1] . "-"
      . $trans[2] . "."
      . $trans[1];
    my $outFilelg2 =
        $options{'outDir'}
      . "/jrc_acquis."
      . $trans[1] . "-"
      . $trans[2] . "."
      . $trans[2];
    my $Foutlg1;
    my $Foutlg2;
    my $docamount = 0;
    my %testInfo = &loadTestInfo($trans[1], $trans[2]);

    # print state
    print "writing jrc_acquis " . $trans[1] . "-" . $trans[2] . "\n";

    # open out files
    open( $Foutlg1, ">:encoding(utf8)", $outFilelg1 )
      || die "Cannot open the output file $outFilelg1:$!\n";
    open( $Foutlg2, ">:encoding(utf8)", $outFilelg2 )
      || die "Cannot open the output file $outFilelg2:$!\n";

    # open alignment file
    open( my $fcelexList, "<:encoding(utf8)", $alignFile )
      || die "Problems opening file $alignFile: $!\n";

    my $jrcid;
    my $testsamples = 0;
    # iterate alignment file lines
    while ( my $line = <$fcelexList> ) {
        chomp $line;
        if ( $line =~ /^[\s]*$/ ) {
            next;
        }
        if ( $line =~ /^#/ ) {
            next;
        }
        my @link = split( /[\s]+/, $line );

        # get celex code and load lang documents
        if ( $line =~ /^[\s]*<div type=\"body\" n=\"([^\"]+)\"/ ) {
            my $celexid = $1;
            my $id = $celexid;
            $id =~ s/\(/_/g;
            $id =~ s/\)//g;
            $id =~ s/\//\#/g;
            my $lg1 = "";
            my $lg2 = "";
            if ( $line =~ /select=\"([a-z][a-z])\s+([a-z][a-z])\"/ ) {
                $lg1 = $1;
                $lg2 = $2;
            }
            $jrcid = "jrc" . $id;
            $docid1 = "jrc" . $id . "-" . $lg1;
            $docid2 = "jrc" . $id . "-" . $lg2;
            $text{ $trans[1] } = &loadParagraphs( $lg1, $celexid, $docid1 );
            $text{ $trans[2] } = &loadParagraphs( $lg2, $celexid, $docid2 );
            $docamount++;
        }

        # output lang files
        if ( $line =~ /^[\s]*<link type=\"([^\"]+)\" xtargets=\"([^\";]+);([^\";]+)\"[\s]*\/>/)
        {
            my $type     = $1;
            my $targets1 = $2;
            my $targets2 = $3;
            $targets1 =~ s/^[\s]+//;
            $targets1 =~ s/[\s]+$//;
            $targets2 =~ s/^[\s]+//;
            $targets2 =~ s/[\s]+$//;

            if ($testInfo{$jrcid}) {
                my $index1 = undef;
                my $element1 = undef;
                while (my ($index, $elem) = each $testInfo{$jrcid}->{$trans[1]}) {
                    if ($targets1 eq $elem) {
                        $index1 = $index;
                        $element1 = $elem;
                    }
                }
                my $index2 = undef;
                my $element2 = undef;
                while (my ($index, $elem) = each $testInfo{$jrcid}->{$trans[2]}) {
                    if ($targets2 eq $elem) {
                        $index2 = $index;
                        $element2 = $elem;
                    }
                }

                if (defined $index1 || defined $element1 || defined $index2 || defined $element2)
                {
                    $testsamples++;
                    #print $targets1 . " " . $targets2 . "\n";
                    #print $element1 . " " . $element2 . "\n";
                }
                else
                {
                    print $Foutlg1 &getSentence( $trans[1], $targets1 ) . "\n";
                    print $Foutlg2 &getSentence( $trans[2], $targets2 ) . "\n";
                }
            }
            else
            {
                print $Foutlg1 &getSentence( $trans[1], $targets1 ) . "\n";
                print $Foutlg2 &getSentence( $trans[2], $targets2 ) . "\n";
            }
        }
    }
    # close all files when one alignment file finished
    close($fcelexList);
    close($Foutlg1);
    close($Foutlg2);
    print "test samples removed: " . $testsamples . "\n";
    print "documents aligned: " . $docamount . "\n";
}

sub loadTestInfo {
    my ( $lg1, $lg2 ) = @_;
    my %testInfo;
    my $testFile = "ac-test.info";

    open( my $F, "<:encoding(utf8)", $testFile ) || do{warn "No test file found, continue"; return();};
    while ( my $line = <$F> ) {
        my ($docid, $remains) = split( /\s/, $line, 2 ); # 0: docid | 1: bg:5,cs:4,da:5,de:5,el:3,...
        $remains =~ s/\s+$//; #  remove trailing spaces
        my @samples = split( /,/, $remains); # 0: bg:5 | 1: cs:4 | 2: da:5 | 3: de:5 | 4: el:3,...
        if (!$testInfo{$docid}) {
            $testInfo{$docid} = {};
        }
        # init hack
        foreach my $sample (@samples) {
            my @spec = split( /:/, $sample); # 0: bg | 1: 5
            if (($lg1 eq $spec[0] || $lg2 eq $spec[0]) && !$testInfo{$docid}->{$spec[0]}) {
                $testInfo{$docid}->{$spec[0]} = [];
            }
        }

        foreach my $sample (@samples) {
            my @spec = split( /:/, $sample); # 0: bg | 1: 5
            if ($lg1 eq $spec[0] || $lg2 eq $spec[0]) {
                push $testInfo{$docid}->{$spec[0]}, $spec[1];
            }
        }
    }
    close $F;
    return %testInfo;
}

sub loadParagraphs {
    my ( $lg, $celexid, $docid ) = @_;

    my $txtInfo = {};
    my $year    = "";
    if ( $celexid =~ /^[0-9A-Z]((19|20)[0-9][0-9])/ ) {
        $year = $1;
    }
    $txtInfo->{celex} = $celexid;
    $txtInfo->{s}     = [];
    my $fileName =
      $options{acquisDir} . $lg . "/" . $year . "/" . $docid . ".xml";

# print "Opening file...",$fileName,"\n";
#  open(my $F, "<:encoding(utf8)", $fileName) || do{warn "Error when reading $fileName: $!"; return();};

    open( my $F, "<:encoding(utf8)", $fileName )
      || die "Problems opening file $fileName: $!\n";
    while ( my $line = <$F> ) {

        # print "LINE:",$line;
        if ( $line =~ /<p n=\"([^\"]+)\">((.|\n|\r)*)<\/p>/i ) {

            #	print  $1,"\t", $2,"\n";
            $txtInfo->{s}->[$1] = $2;
        }
    }
    close $F;
    return $txtInfo;
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
