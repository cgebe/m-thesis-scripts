#!/bin/perl
#
# script that add the text to the alignment information
#
# CREATION 15/03/2006 Camelia Ignat
# Modified:
# V1.01 15/05/2006 Camelia Ignat - take in account a little changement of input format (no more linkGrp)
# V1.02  13/07/2007 Camelia Ignat - add more documentation, add again linkGrp tag, deal with "/" character in celex code...
#

our $VERSION=1.02;


use strict; use warnings;

my %options=(
	     'acquisDir' => 'acquis/*',
         'alignDir' => 'align/*',
	     'outDir' => '',
	    );

binmode(STDOUT,"utf8");
binmode(STDIN,"utf8");

# Initialisations

my %text=();

my %celexCodes;
my $select=0;
my $sizesel=0;

my @acquis = <$options{acquisDir}>;
my @aligns = <$options{alignDir}>;
foreach my $alignFile (@aligns) {
  my @names = split(/\./, $alignFile);
  my @trans = split('-', $names[0]); # get language pair
  my $langDir1 = $options{acquisDir} . "/" . $trans[0];
  my $langDir2 = $options{acquisDir} . "/" . $trans[1];
  my $celexcode;
  open(my $fcelexList, "<:encoding(utf8)", $alignFile) || die "Problems opening file $alignFile: $!\n";
  while(my $line = <$fcelexList>){
    chomp $line;
    if($line =~ /^[\s]*$/){
      next;
    }
    if($line =~ /^#/){
      next;
    }
    my @link = split(/[\s]+/, $line);

    # get celex code
    if ($link[0] eq "<linkGrp") {
        if (beginsWith($link[3], "n=")) {
            my @celex = split(/"/, $link[3]);
            $celexcode = $celex[1];
            print "$celexcode" . "\n";
        } else {
            die "wrong type for linkgrp $alignFile";
        }
    }

  }
  close($fcelexList);

  # outputAlignedCorpusFromFile($langDir1, $langDir2, $alignFile)
}

if(($options{alignDir} ne "") && (-f $options{alignDir})){
  $select=1;
  open(my $fcelexList, "<:encoding(utf8)", $options{selectionList}) || die "Problems opening file $options{selectionList}: $!\n";
  while(my $line = <$fcelexList>){
    chomp $line;
    if($line =~ /^[\s]*$/){
      next;
    }
    if($line =~ /^#/){
      next;
    }
    my ($celex, $rest) = split(/[\s]+/,$line,2);
   # print STDERR "Celex codes: ",$celex,"\n";
    $celexCodes{$celex}=1;
    $sizesel++;
  }
  close($fcelexList);
}

foreach my $file (@ARGV) { # allows for several alignment text files
  # outputAlignedCorpusFromFile($file);
}

sub outputAlignedCorpusFromFile{
    my($file) = @_;

    open(my $Fal, "<:encoding(utf8)",$file) || die "pb reading alignment file $file:$!";

    my $docid1="";
    my $docid2="";
    my $celexid="";
    my $lg1="";
    my $lg2="";

    my $Fout;
    if($options{'outDir'} ne ""){
      unless(-d $options{'outDir'}){
	system("mkdir -p $options{'outDir'}");
      }
      $options{outDir} =~ s/\/$//;
      my $outFile = $file;
      $outFile =~ s/^.*\/([^\/]+)$/$1/;
      $outFile =~ s/(.+)\.([^\.]+)/$1\_withText\.$2/;
      $outFile = $options{'outDir'}."/".$outFile;
      open($Fout,">:encoding(utf8)",$outFile) || die "Cannot open the output file $outFile:$!\n";
    }
    else{
      $Fout=*STDOUT;
    }

    my $writeDoc=1;
    while (my $line = <$Fal>) {

      unless(($line =~ /^[\s]*<link/) || ($line =~ /^[\s]*<linkGrp/) || ($line =~ /^[\s]*<div type=\"body\"/)){
	if($writeDoc eq 1){
	  if(($select eq 1)&&($line =~ /<extent>/)){
	    $line =~ s/<extent>/<extent>Selection of maximum $sizesel documents from: /;
	  }
	  print $Fout $line;

	}
	elsif($line =~ /<\/div>/){
	  $writeDoc=1;
	}
	next;
      }
      chomp($line);
      if($line =~ /^[\s]*<div type=\"body\" n=\"([^\"]+)\"/){
	$celexid=$1;
	if(($select eq 1) && (not exists $celexCodes{$celexid})){
	  $celexid="";
	  $writeDoc=0;
	}
	else{
	  $writeDoc=1;
	  if($line =~ /select=\"([a-z][a-z])\s+([a-z][a-z])\"/){
	    $lg1=$1;
	    $lg2=$2;
	  }
	  my $id=$celexid;
	  $id =~ s/\(/_/g;
	  $id =~ s/\)//g;
	  $id =~ s/\//\#/g;
	  $docid1="jrc".$id."-".$lg1;
	  $docid2="jrc".$id."-".$lg2;
	  $text{$lg1} = &getTextInfoFromXmlFile($lg1,$celexid, $docid1);
	  $text{$lg2} = &getTextInfoFromXmlFile($lg2,$celexid, $docid2);
	  print $Fout $line,"\n";
	}
	next;
      }
      if($writeDoc eq 0){
	next;
      }
      if($line =~ /^[\s]*<linkGrp/){

#	if($line =~ /xtargets=\"([^\";]+);([^\";]+)\"/){
#	  $docid1=$1;
#	  $docid2=$2;
#	}
#	if($line =~ /select=\"([a-z][a-z])\s+([a-z][a-z])\"/){
#	  $lg1=$1;
#	  $lg2=$2;
#	}
#	# print "TEST:",$docid1, "\t",$docid2,"\t", $celexid, "\t", $lg1, "\t", $lg2, "\n";
#	$text{$lg1} = &getTextInfoFromXmlFile($lg1,$celexid, $docid1);
#	$text{$lg2} = &getTextInfoFromXmlFile($lg2,$celexid, $docid2);
	print $Fout $line,"\n";
	next;
      }

      if($line =~ /^[\s]*<link type=\"([^\"]+)\" xtargets=\"([^\";]+);([^\";]+)\"[\s]*\/>/){
	my $type=$1;
	my $targets1=$2;
	my $targets2=$3;
	$targets1 =~ s/^[\s]+//;
	$targets1 =~ s/[\s]+$//;
	$targets2 =~ s/^[\s]+//;
	$targets2 =~ s/[\s]+$//;

	if($celexid eq ""){
	#  print $Fout $line,"\n";
	}
	else{
	  $line =~ s/[\s]*\/>$/>/;
	  print $Fout $line,"\n";
	  print $Fout &addTextLanguage($lg1, $targets1, 1);
	  print $Fout &addTextLanguage($lg2, $targets2, 2);
	  print $Fout "<\/link>\n";
	}
	next;
      }
    }
    if($options{'outDir'} ne ""){
      close($Fout);
    }
  }



sub addTextLanguage{
  my ($lg, $targets1, $n)=@_;

  my $string = "";
  my @targets1 = split(/[\s]+/,$targets1);

  if(scalar @targets1 > 0){
    $string .= "<s$n>";
    foreach my $t (@targets1){
      if(scalar @targets1 > 1){
	$string .= "<p>";
      }
      $string .= $text{$lg}->{s}->[$t];
      if(scalar @targets1 > 1){
	$string .= "</p>";
      }
    }
    $string .= "<\/s$n>\n";
  }
  else{
    $string .= "<s$n\/>\n";
  }
			      return $string;
}


sub getTextInfoFromXmlFile {
    my($lg,$celexid, $docid) = @_;

    my $txtInfo={};
    my $year="";
    if($celexid =~ /^[0-9A-Z]((19|20)[0-9][0-9])/){
      $year=$1;
    }
    $txtInfo->{celex}=$celexid;
    $txtInfo->{s} = [];
    my $fileName=$options{acquisDir}."/".$lg."/".$year."/".$docid.".xml";
    # print "Opening file...",$fileName,"\n";
  #  open(my $F, "<:encoding(utf8)", $fileName) || do{warn "Error when reading $fileName: $!"; return();};

  open(my $F, "<:encoding(utf8)", $fileName) || die "Problems opening file $fileName: $!\n";
    while (my $line = <$F>) {
     # print "LINE:",$line;
      if($line =~ /<p n=\"([^\"]+)\">((.|\n|\r)*)<\/p>/i) {
#	print  $1,"\t", $2,"\n";
	$txtInfo->{s}->[$1]=$2;
      }
    }
    close $F;
   return $txtInfo;
}

sub beginsWith
{
    return substr($_[0], 0, length($_[1])) eq $_[1]
}


__END__


=head1 NAME


getAlignmentWithText.pl - program that add the text to the alignment files.


=head1 SYNOPSIS


  perl getAlignmentWithText.pl  -acquisDir "JRC-Acquis_corpus_folder"  jrc-en-fr.xml  >en-fr_alignedCorpus_withText.xml

  To select only the document from a list of celex codes :
  perl getAlignmentWithText.pl  -acquisDir "JRC-Acquis_corpus_folder"  -selectionList "file_withCelexCode" jrc-en-fr.xml  >en-fr_alignedCorpus_withText.xml

  To process more files use an output folder as following:
  perl getAlignmentWithText.pl  -acquisDir "JRC-Acquis_corpus_folder"  -selectionList "file_withCelexCode" -outDir "Output_folder"  jrc-bg-cs.xml  jrc-en-it.xml


=head1 DESCRIPTION

To get the aligned corpora for a language pair, the program need as input the corpora by language and the alignment information. The corpora will be provided by the option "acquisDir" that will specify where the Acquis corpus is located. If the option is not specified the default value is the current directory.
The alignment information will be provided as argument.

Using the option "selectionList" you can provided a list of Celex codes that has to be processed and the programm will output only the files that has the Celex code specified in the list. The codes are given in a file - one celex code by line. This option could be useful if you want to process only documents that have Eurovoc descriptors.

The option "outDir" gives the possibility to process more than one language pair. You have to specify all the language pairs that you want to process as arguments and to give the output directory where the alignments with text will be written.
 The result files will have the name composed by the name of the input file (without extension) followed by "_withText", followed by the extension (i.e. jrc-en-fr_withText.xml)


The program outputs an aligned corpus, containing documents in the following format:


  ...
  <teiHeader>....header....<teiHeader>
    <text select="fr ro">
      <body>
          <p>19 paragraph links:</p>
  <linkGrp targType="head p" n="22002D0163" select="fr ro" id="jrc22002D0163-fr-ro" type="1-1" xtargets="jrc22002D0163-fr;jrc22002D0163-ro">
     <link type="1-1" xtargets="1;1">
       <s1>Décision du Comité mixte de l'EEE </s1>
       <s2>DECIZIA COMITETULUI MIXT AL SEE </s2>
     </link>
     <link type="1-1" xtargets="2;2">
       <s1>no 163/2002</s1>
       <s2>nr. 163/2002</s2>
     </link>
     <link type="1-1" xtargets="3;3">
       <s1>du 6 décembre 2002</s1>
       <s2>din 6 decembrie 2002</s2>
     </link>
     <link type="1-1" xtargets="4;4">
       ....


The file is fully XML, we must use the UTF-8 encoding to handle all character sets
(French-Greek for example).

Example of use for Lithuanian-Swedish alignment:

Before launching it make sure you have uncompressed (using gunzip command for example) the alignment file.

   gunzip jrc-lt-sv.xml.gz

Then, you need to get and unpack the two corpora:

  tar xzf jrc-lt.tgz
  tar xzf jrc-sv.tgz

Then you can launch this program using a perl5 interpreter:

  perl getAlignmentWithText.pl  -acquisDir . jrc-lt-sv.xml > jrc-lt-sv_withText.xml


=head1 COMMENTS


We have deliberately chosen to parse the texts without an XML parser. The format of Xml texts is well known, and the script has to be as fast as possible to handle 8000 texts in less than 5 minutes.


=head1 AUTHORS


camelia.ignat@jrc.it, bruno.pouliquen@jrc.it


=cut
