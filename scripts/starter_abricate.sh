#!/usr/bin/env bash

###Usage###
# bash $PathToScript/Scriptname.sh -h

###Author###
#Margo Diricks (mdiricks@fz-borstel.de)!"

###Version###
version="1.0.0"

###Function###
#echo "This script runs abricate"

###Required packages###
# abricate, installed in a conda environment called abricate 

###Required parameters - via command line###
#-i PATH_fastQ=""
#-o PATH_output=""
#-d db=""

###Optional parameters that can be changed###
minid=80 #Default 80
mincov=80 #Default 80

cpu=$(lscpu | grep -E '^CPU\(' | awk '{print $(NF)}') #Uses all available threads
conda_env="abricate"
#PATH_tmp="$HOME/tmp"
Analysis="Abricate"

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Syntax: NameScript.sh [parameters]"
   echo "Required parameters:"
   echo "-i     Full path to folder where fasta files are stored"
   echo "-o     Full path to folder where result files need to be stored"
   echo "-d     Database (default NCBI; other options: argannot, card, ecoh, ecoli_vf, megares, plasmidfinder, resfinder, vfdb)"
   echo ""
   echo "Optional parameters":
   echo "-c     amount of cpus that need to be used (depends on your hardware configuration); Default: All"
   echo "-e     Name of conda environment; Default: SRST2"
   echo "-p     Minimum coverage; Default: 80"
   echo "-s     Minimum identity; Default: 80"
   echo "-t     Full path to directory where temporary files will be stored; Default: $HOME/tmp"
   echo ""
   echo "-v     Display version"
   echo "-h     Display help"
}
############################################################
# Get parameters                                                #
############################################################

while getopts ":hi:o:c:d:p:s:t:e::v" option; do #:h does not need argument, f: does need argument
   case $option in
      h) # display Help
         Help
         exit;;
      i) #
         PATH_fastA=$OPTARG;;
      o) # 
         PATH_output_tmp=$OPTARG
         PATH_output=$PATH_output_tmp/$Analysis ;;
      d) # 
         db_abricate=$OPTARG;;
      c) # 
         cpu=$OPTARG;;
      p) #
         mincov=$OPTARG;;
      s) # 
         set=$OPTARG;;
      t) # 
         PATH_tmp=$OPTARG;;
      e) # 
         conda_env=$OPTARG;;
      v) # display Version
         echo $version
         exit;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

###Check if required parameters are provided###
if [[ -z "$PATH_fastA" ]] || [[ -z "$PATH_output" ]] || [[ -z "$db_abricate" ]]
then
	echo "Please provide all required arguments (-i PATH_fastA, -o PATH_output and -d db_abricate)! use starter_abricate.sh -h for help on syntax"
	exit
fi

###############################################################################CODE#################################################################################
#Remove previous files
rm $PATH_output/failed.txt
rm $PATH_output/Summary_abricate.tab

###Create folders###
mkdir -p $PATH_output
#mkdir -p $PATH_tmp

###Activate conda environment###

eval "$(conda shell.bash hook)"
conda activate $conda_env

###Create info file###

date > $PATH_output/info.txt
echo "Version script: "$version >> $PATH_output/info.txt
echo "Abricate database used: "$db_abricate >> $PATH_output/info.txt
echo "abricate version: "$(abricate --version) >> $PATH_output/info.txt
echo "Minimum identity : "$minid  >> $PATH_output/info.txt
echo "Mininum coverage: "$mincov >> $PATH_output/info.txt
echo "Input files: "$PATH_fastA >> $PATH_output/info.txt
echo "Output files:"$PATH_output >> $PATH_output/info.txt
echo "Amount of threads used: "$cpu >> $PATH_output/info.txt
echo "Conda environment: "$conda_env >> $PATH_output/info.txt
echo "Amount of samples in input folder:" $(ls $PATH_fastA/*.fasta | wc -l) >> $PATH_output/info.txt
echo "Databases:" $(abricate --list) >> $PATH_output/info.txt

###Start abricate###
for file in $PATH_fastA/*.fasta
do
	SampleName=$(basename $file| cut -d '_' -f 1 | cut -d '.' -f 1)
	if [ -f $PATH_output/$SampleName.tab ]
	then
		echo $SampleName "Already analysed"
	else
		abricate $file --db $db_abricate --threads $cpu --nopath --minid $minid --mincov $mincov > $PATH_output/$SampleName.tab
		#Clean up
		rm $PATH_output/$SampleName/*.chromosome.fasta
		rm $PATH_output/$SampleName/$SampleName.json
	fi
done

###Make summary file###
list=""

# Loop through all .tab files in the folder
for file in $PATH_output/*.tab; do
    # Append the filename to the list variable, separated by a space
    list+="$file "
done

# Remove the trailing whitespace
list=${list% }

# Print the list variable to verify
echo "$list"

abricate --summary $list > $PATH_output/Summary_abricate.tab

###Closing###
conda deactivate
echo "Script Finished!" >> $PATH_output/info.txt
date >> $PATH_output/info.txt


####################################################################CODE THAT MIGHT BE USED IN ADDITION#################################################################################

###Clean up###
#rm $PATH_output/*.bam


###############################################################################HELP#################################################################################


###Program parameters###
# SYNOPSIS
  # Find and collate amplicons in assembled contigs
# AUTHOR
  # Torsten Seemann (@torstenseemann)
# USAGE
  # % abricate --list
  # % abricate [options] <contigs.{fasta,gbk,embl}[.gz] ...> > out.tab
  # % abricate [options] --fofn fileOfFilenames.txt > out.tab
  # % abricate --summary <out1.tab> <out2.tab> <out3.tab> ... > summary.tab
# GENERAL
  # --help          This help.
  # --debug         Verbose debug output.
  # --quiet         Quiet mode, no stderr output.
  # --version       Print version and exit.
  # --check         Check dependencies are installed.
  # --threads [N]   Use this many BLAST+ threads [1].
  # --fofn [X]      Run on files listed in this file [].
# DATABASES
  # --setupdb       Format all the BLAST databases.
  # --list          List included databases.
  # --datadir [X]   Databases folder [/molmyc/miniconda3/envs/abricate/db].
  # --db [X]        Database to use [ncbi].
# OUTPUT
  # --noheader      Suppress column header row.
  # --csv           Output CSV instead of TSV.
  # --nopath        Strip filename paths from FILE column.
# FILTERING
  # --minid [n.n]   Minimum DNA %identity [80].
  # --mincov [n.n]  Minimum DNA %coverage [80].
# MODE
  # --summary       Summarize multiple reports into a table.
# DOCUMENTATION
  # https://github.com/tseemann/abricate

						
exit 