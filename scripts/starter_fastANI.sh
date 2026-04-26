#!/usr/bin/env bash

###Usage###
# bash $PathToScript/Scriptname.sh -h

###Author###
#Margo Diricks (mdiricks@fz-borstel.de)!"

###Version###
version="1.0.0"

###Function###
#echo ""

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
Analysis="fastANI"
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
   echo "-r     Full path to reference ($PATH)"
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

while getopts ":hi:o:c:r:e::v" option; do #:h does not need argument, f: does need argument
   case $option in
      h) # display Help
         Help
         exit;;
      i) #
         PATH_fastA=$OPTARG;;
      o) # 
         PATH_output_tmp=$OPTARG
         PATH_output=$PATH_output_tmp/$Analysis ;;
      r) # 
         ref=$OPTARG;;
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
if [[ -z "$PATH_fastA" ]] || [[ -z "$PATH_output" ]] || [[ -z "$ref" ]]
then
	echo "Please provide all required arguments (-i PATH_fastA, -o PATH_output and -r reference)! use starter_fastANI.sh -h for help on syntax"
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
echo "Reference used: "$ref >> $PATH_output/info.txt
echo "FastANI version: "$(fastANI -v) >> $PATH_output/info.txt #Does not work, outputs in command line
echo "Input files: "$PATH_fastA >> $PATH_output/info.txt
echo "Output files:"$PATH_output >> $PATH_output/info.txt
echo "Amount of threads used: "$cpu >> $PATH_output/info.txt
echo "Conda environment: "$conda_env >> $PATH_output/info.txt
echo "Amount of samples in input folder:" $(ls $PATH_fastA/*.$file_ext | wc -l) >> $PATH_output/info.txt


for fasta in $PATH_fastA/*.$file_ext
do
	SampleName=$(basename $fasta| cut -d '.' -f 1)
	if [ -f "$PATH_output/"$SampleName"_fastani.out" ]
	then
		 echo "Sample was already analysed"
	else
		fastANI -q $fasta -r $ref -t $cpu -o $PATH_output/$SampleName"_fastani.out"
	fi
done

#Create summary file
echo -e "Sample\tRef\tTotal_fragments_sample\tfragments_aligned_withRef" > $PATH_output/summary_fastANi.txt

for result in $PATH_output/*"_fastani.out"
do
	if [ -s $result ]
	then
		SampleName=$(basename $result| cut -d '.' -f 1 | cut -d '_' -f 1)
		Ref=$(basename $ref| cut -d '.' -f 1)
		ANI=$(cat $result | cut -f 3)
		Total_frag=$(cat $result | cut -f 4)
		Frag_aligned=$(cat $result | cut -f 5)
		paste --delimiter='\t'  <(echo $SampleName)	<(echo $Ref) <(echo $ANI) <(echo $Total_frag) <(echo $Frag_aligned) >> $PATH_output/summary_fastANi.txt
	else
		SampleName=$(basename $result| cut -d '.' -f 1 | cut -d '_' -f 1)
		Ref=$(basename $ref| cut -d '.' -f 1)
		ANI=""
		Total_frag=""
		Frag_aligned=""
		paste --delimiter='\t'  <(echo $SampleName)	<(echo $Ref) <(echo $ANI) <(echo $Total_frag) <(echo $Frag_aligned) >> $PATH_output/summary_fastANi.txt
	fi
done

	

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