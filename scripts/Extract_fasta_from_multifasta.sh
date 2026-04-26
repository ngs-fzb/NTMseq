#! /bin/bash

###Usage###
# bash $PathToScript/Scriptname.sh -h

###Author###
#Margo Diricks (mdiricks@fz-borstel.de)!"

###Version###
version="1.0.0"

###Function###
#echo "Running this script will extract fasta sequences from a multi-fasta file using a list of IDs in seperate fasta files"

###Required packages###
# seqkit, in a conda environment called seqkit

###Required parameters - via command line###
#-i PATH_ID=""
#-m PATH_multifasta=""
#-o PATH_output=""

###Optional parameters that can be changed###
conda_env="seqkit"

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Syntax: NameScript.sh [parameters]"
   echo "Required parameters:"
   echo "-i     Full path to file with IDs (one ID per row). These IDs must be part of the header of the respective sequence in the multi-fasta file"
   echo "-m     Full path to multi-fasta file "
   echo "-o     Full path to folder where result files need to be stored"
   echo ""
   echo "Optional parameters":
   echo "-e     Name of conda environment; Default: seqkit"
   echo ""
   echo "-v     Display version"
   echo "-h     Display help"
}
############################################################
# Get parameters                                                #
############################################################

while getopts ":hi:o:m:e::v" option; do #:h does not need argument, f: does need argument
   case $option in
      h) # display Help
         Help
         exit;;
      i) #
         PATH_ID=$OPTARG;;
      m) # 
         PATH_multifasta=$OPTARG;;
      o) # 
         PATH_output=$OPTARG;;
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
if [[ -z "$PATH_ID" ]] || [[ -z "$PATH_output" ]] || [[ -z "$PATH_multifasta" ]]
then
	echo "Please provide all required arguments (-i PATH_ID, PATH_multifasta and -o PATH_output)! use starter_download_plasmids.sh -h for help on syntax"
	exit
fi

###############################################################################CODE#################################################################################

###Create folders###
mkdir -p $PATH_output

###Activate conda environment###
eval "$(conda shell.bash hook)"
conda activate $conda_env


while read line
do
	[[ ! -s $PATH_output/$line.fasta ]] && cat $PATH_multifasta | seqkit grep -r -p .*$line.* > $PATH_output/$line.fasta
done <<< "$(cat $PATH_ID)"

conda deactivate
echo "Script Finished!"
exit
