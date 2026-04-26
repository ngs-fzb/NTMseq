#!/usr/bin/env perl

###Usage###
# perl $PathToScript/Scriptname.pl -h

###Author###
#Christian Utpatel, modified by Margo Diricks (mdiricks@fz-borstel.de)

###Dependecies###
use strict; # disables certain Perl expressions that could behave unexpectedly or are difficult to debug, turning them into errors
use warnings;
use Getopt::Long;
use File::Basename;
use Time::HiRes qw( time ); #Used to calculate elapsed time

###Version###
my $version = "1.0.22";

###Get time###
my $datestring = localtime();
my $begin_time = time();

###initialize command-line parameter.###
my $opt_version         =      "";
my $species             =      "none";
my $help                =      "";

###get command-line parameter.
GetOptions('version|v'       =>    \$opt_version,
           'species|s:s'     =>    \$species,
           'help|h'          =>     \$help);
print "Species of interest: $species\n";

###print help message if specified or version if specified.
if($help eq '1') { help($version);     exit 0; } #if someone evokes the help function i.e. perl $PathToScript/Scriptname.pl -h
if($opt_version eq '1') { version($version);     exit 0; } # if someone evokes the version version i.e. perl $PathToScript/Scriptname.pl -v
#if($species eq 'none') { $species = "Mycobacterium tuberculosis complex"; }

###get files from command-line.
my @kraken_files = @ARGV; #kraken-report files
die "<ERROR>\t",$datestring,"\tNo Kraken-report files specified. Use --help for usage instructions.\n" if ! @kraken_files;
my $PATH_output = dirname($kraken_files[0]);
print "PATH_output is $PATH_output\n";

###Create info file###
open(info_s,">","$PATH_output/info_kraken_summary.txt") or die "\n<ERROR>\t",$datestring,"\tUnable to create kraken_info_summary.txt\n";
print info_s "###Info on kraken_summary.tsv file###\n";
print info_s "Start:\t $datestring\n";
print info_s "Used files located at:\t $PATH_output\n";
print info_s "Making a summary file with $species as species of interest\n";
close (info_s);

###run on all input kraken-report files.
my $krakenfile;

open(OUT,">","$PATH_output/kraken_summary.tsv") or die "\n<ERROR>\t",$datestring,"\tUnable to create kraken_summary.tsv\n";
  my $strain_header = "SampleID\tUnclassified_perc\tUnclassified_reads\tTotal_reads\tHuman_perc\tBacteria_perc\tMycobacterium_perc\tSpecies\tSpecies_perc\tSpecies_other_max\tSpecies_other_max_perc\tSpecies_Myco_max\tSpecies_Myco_max_perc\tSpecies_nonMyco_max\tSpecies_nonMyco_max_perc\tGenus_max\tGenus_max_perc\tGenus_max_nonMyco\tGenus_max_nonMyco_perc\n";
  print OUT $strain_header;
foreach my $file (@kraken_files) {
  next unless (-f "$file");
  next unless ($file =~ /^(.+).report/);
  $krakenfile = $1;
  my $sampleID = basename($krakenfile);
  print "\n<INFO>\t",$datestring,"\tProcessing $sampleID\n";
    
  open(Fin, "<", $file) or die "\n<ERROR>\t",$datestring,"\tUnable to open $file\n";

  my $u_perc = 0; #percentage of reads unclassified
  my $u_reads = 0; #amount of reads unclassified
  my $root_reads = 0; # amount of reads at root (i.e. classified reads)
  my $Total_reads = 0; # amount of total reads (classified + unclassified); 
  my $hum_perc = 0; #percentage human reads
  my $bac_perc = 0; #percentage bacterial reads
  my $mycobacterium_perc = 0; #Percentage mycobacterium reads
  my $species_perc = 0; #percentage reads of species of interest
  my $species_max; #name of species with maximum amount of reads and percentage reads
  my $species_max_perc = 0; #perc of most prevalent species other than selected one
  my $species_max_nonMyco = 0; #name of species with maximum amount of reads and percentage reads that does not belong to genus mycobacteria
  my $species_max_nonMyco_perc = 0; #perc of most prevalent species that does not belong to genus Mycobacterium
  my $species_max_Myco = 0; #name of species with maximum amount of reads and percentage reads that does not belong to genus mycobacteria
  my $species_max_Myco_perc = 0; #perc of most prevalent species that does not belong to genus Mycobacterium
  my $genus_max = 0; #name of genus with maximum amount of reads
  my $genus_max_perc = 0; #perc of most prevalent genus
  my $genus_max_nonMyco = 0; #name of genus with 2nd maximum amount of reads
  my $genus_max_nonMyco_perc = 0; #perc of 2nd most prevalent genus
	
	while (my $line = <Fin>){
	$line          =~  s/\015?\012?$//; #Deal with breaklines
	my @line = split("\t",$line);
	my $perc = $line[0];
	my $read_clade = $line[1];
	my $read_taxon = $line[2];
	my $rank = $line[3];
	my $taxid = $line[4];
	my $name = $line[5];
	$name =~ s/^\s+//; #To remove spaces at the beginning
	
		if ($name eq "unclassified") {
		$u_reads = $read_clade;
		$u_perc = $perc;
		}
		if ($name eq "root") {
		$root_reads = $read_clade;
		}
		$Total_reads = add($u_reads , $root_reads);
		if ($rank eq "G" and $name eq "Mycobacterium") {
		$mycobacterium_perc = $perc;
		}		
		if ($rank eq "G" and $perc >= $genus_max_perc and $name ne "Homo") {
		$genus_max_perc = $perc;
		$genus_max = $name;
		}
		if ($rank eq "G" and $perc >= $genus_max_nonMyco_perc and $name !~ /Mycobacterium/ and $name !~ /Mycolicibacterium/ and $name !~ /Mycobacteroides/ and $name !~ /Mycolicibacillus/ and $name !~ /Mycolicibacter/){
		$genus_max_nonMyco_perc = $perc;
		$genus_max_nonMyco = $name;
		} 	
		if ($rank eq "S" and $perc >= $species_max_perc and $name ne "Homo sapiens"and $name ne $species) {
		$species_max_perc = $perc;
		$species_max=$name;
		}
		if ($rank eq "S" and $perc >= $species_max_Myco_perc and $name ne "Homo sapiens"and ( $name =~ /Mycobacterium/ or $name !~ /Mycolicibacterium/ or $name !~ /Mycobacteroides/ or $name !~ /Mycolicibacillus/ or $name !~ /Mycolicibacter/)){
		$species_max_Myco_perc = $perc;
		$species_max_Myco=$name;
		} 		
		if ($rank eq "S" and $perc >= $species_max_nonMyco_perc and $name ne "Homo sapiens"and $name !~ /Mycobacterium/ and $name !~ /Mycolicibacterium/ and $name !~ /Mycobacteroides/ and $name !~ /Mycolicibacillus/ and $name !~ /Mycolicibacter/){
		$species_max_nonMyco_perc = $perc;
		$species_max_nonMyco=$name;
		} 		
		if ($rank eq "S" and $name eq $species){
		$species_perc = $perc;
		}
		if ($rank eq "S" and $name=~/^Homo\ssapiens$/){
		$hum_perc = $perc;
		}
		if ($rank eq "D" and $name=~/^Bacteria$/){
		$bac_perc = $perc;
		}
	
}
print OUT "$sampleID\t$u_perc\t$u_reads\t$Total_reads\t$hum_perc\t$bac_perc\t$mycobacterium_perc\t$species\t$species_perc\t$species_max\t$species_max_perc\t$species_max_Myco\t$species_max_Myco_perc\t$species_max_nonMyco\t$species_max_nonMyco_perc\t$genus_max\t$genus_max_perc\t$genus_max_nonMyco\t$genus_max_nonMyco_perc\n";
close (Fin);
}
close (OUT);

###Finish info file###
my $end_time = time();
my $elapsed_time = sprintf("%.2f\n", $end_time - $begin_time);

open(info_e,">>","$PATH_output/info_kraken_summary.txt") or die "\n<ERROR>\t",$datestring,"\tUnable to create kraken_info_summary.txt\n";
print info_e "END:\t $datestring\n";
print info_e "Elapsed time (s):\t $elapsed_time";
close (info_e);

exit(0);

sub help { # print a help message.
   my $version = shift;
   print
   "

   kraken_parse_results.pl $version - For help: ask Margo Diricks (mdiricks\@fz-borstel.de)
   
   [USAGE]: [--OPTION PARAMETER] <.report file>
   
   Available OPTIONS:
   -s [--species]       Species of interest (mandatory)
   -h [--help]          This help message
   
   -v [--version]       Print version
   
   ";
   print "\n";
}


sub version { # print the version
   print "$version\n"
}

sub add
{
    my ($x,$y) = @_;
    my $res = $x + $y ;
    return $res ;   
}