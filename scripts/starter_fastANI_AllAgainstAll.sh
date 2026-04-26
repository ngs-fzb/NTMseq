#!/usr/bin/env bash

###Usage###
# bash $PathToScript/Scriptname.sh -h

###Author###
#Margo Diricks (mdiricks@fz-borstel.de)!"

###Version###
version="1.0.0"

###Function###
#echo "This script calculates ANI between all fastas in the specified folder"

###Required packages###
# fastani , installed in a conda environment called fastani

###Required parameters - via command line###
#-i PATH_fastA=""
#-o PATH_output=""
#-r ref=""

###Optional parameters that can be changed###
cpu=$(lscpu | grep -E '^CPU\(' | awk '{print $(NF)}') #Uses all available threads
conda_env="fastani"
#PATH_tmp="$HOME/tmp"
Analysis="fastANI_AllagainstAll"
file_ext="fasta"

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
   echo ""
   echo "Optional parameters":
   echo "-c     amount of cpus that need to be used (depends on your hardware configuration); Default: All"
   echo "-e     Name of conda environment; Default: fastani"
   echo ""
   echo "-v     Display version"
   echo "-h     Display help"
}
############################################################
# Get parameters                                                #
############################################################

while getopts ":hi:o:c:e::v" option; do #:h does not need argument, f: does need argument
   case $option in
      h) # display Help
         Help
         exit;;
      i) #
         PATH_fastA=$OPTARG;;
      o) # 
         PATH_output_tmp=$OPTARG
         PATH_output=$PATH_output_tmp/$Analysis ;;
      c) # 
         cpu=$OPTARG;;
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
if [[ -z "$PATH_fastA" ]] || [[ -z "$PATH_output" ]]
then
	echo "Please provide all required arguments (-i PATH_fastA and -o PATH_output)! use starter_fastANI.sh -h for help on syntax"
	exit
fi

###############################################################################CODE#################################################################################

###Create folders###
mkdir -p $PATH_output
#mkdir -p $PATH_tmp

###Activate conda environment###

eval "$(conda shell.bash hook)"
conda activate $conda_env

###Create info file###

date > $PATH_output/info.txt
echo "Version script: "$version >> $PATH_output/info.txt
echo "FastANI version: "$(fastANI -v) >> $PATH_output/info.txt #Does not work, outputs in command line
echo "Input files: "$PATH_fastA >> $PATH_output/info.txt
echo "Output files:"$PATH_output >> $PATH_output/info.txt
echo "Amount of threads used: "$cpu >> $PATH_output/info.txt
echo "Conda environment: "$conda_env >> $PATH_output/info.txt
echo "Amount of samples in input folder:" $(ls $PATH_fastA/*.$file_ext | wc -l) >> $PATH_output/info.txt

find $PATH_fastA -type f \( -name "*.fasta" -o -name "*.fa" \) > $PATH_output/fasta_paths.txt
fastANI --ql $PATH_output/fasta_paths.txt --rl $PATH_output/fasta_paths.txt -o $PATH_output/fastANI_allToAll_summary.csv -t $cpu



###Closing###
conda deactivate
echo "Script Finished!" >> $PATH_output/info.txt
date >> $PATH_output/info.txt


####################################################################CODE THAT MIGHT BE USED IN ADDITION#################################################################################

###Clean up###
#rm $PATH_output/*.bam


###############################################################################HELP#################################################################################


###Program parameters###

						
exit 