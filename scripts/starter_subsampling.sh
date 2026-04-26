#!/usr/bin/env bash

###Usage###
# bash $PathToScript/Scriptname.sh -h

###Author###
#Margo Diricks (mdiricks@fz-borstel.de)!"

###Version###
version="2.0.0"

###Function###
#echo "This script downsamples paired fastQ reads to the desired coverage based on the estimated coverage"

###Required packages###
# seqtk and pigz, installed in a conda environment called seqtk

###Required parameters - via command line###
#-i PATH_fastQ=""
#-o PATH_output=""
#-d db=""

###Optional parameters that can be changed###
Fw="_R1" #Change if your fastQ files are not SampleName_R1.fastq.gz
Rv="_R2" #Change if your fastQ files are not SampleName_R2.fastq.gz
filetype=".fastq.gz"
cpu=$(lscpu | grep -E '^CPU\(' | awk '{print $(NF)}') #Uses all available threads
set="SampleSet"
conda_env=""
Min_BQ=3 #Minimum base quality...to anticipate on the fact that during assembly with shovill bases will be trimmed with quality below 3
#PATH_tmp="$HOME/tmp"
Analysis="FastQ_subsampled"

############################################################
# Help                                                     #
############################################################
Help()
{
   # Display Help
   echo "Syntax: NameScript.sh [parameters]"
   echo "Required parameters:"
   echo "-i     Full path to folder where fastq files are stored"
   echo "-o     Full path to folder where result files need to be stored"
   echo "-g     expected genome size - depends on NTM species. M. abscessus=5.1M. Other species: check median genome size on NCBI"
   echo "-d     reads will be downsampled to reach this theoretic coverage; Default: 100"
   echo ""
   echo "Optional parameters":
   echo "-c     amount of cpus that need to be used (depends on your hardware configuration); Default: All"
   echo "-e     Name of conda environment; Default: seqtk"
   echo "-f     Forward read notation; Default: _R1"
   echo "-r     Reverse read notation; Default: _R2"
   echo "-s     Name of sample set - used for file naming; Default: Sampleset"
   echo "-t     Full path to directory where temporary files will be stored; Default: $HOME/tmp"
   echo ""
   echo "-v     Display version"
   echo "-h     Display help"
}
############################################################
# Get parameters                                                #
############################################################

while getopts ":hi:o:c:d:g:f:r:s:t:e::v" option; do #:h does not need argument, f: does need argument
   case $option in
      h) # display Help
         Help
         exit;;
      i) #
         PATH_fastQ=$OPTARG;;
      o) # 
         PATH_output_tmp=$OPTARG
         PATH_output=$PATH_output_tmp/$Analysis ;;
      g) # 
         genome_size=$OPTARG;;
      c) # 
         cpu=$OPTARG;;
      d) # 
         cov=$OPTARG;;
      f) # 
         Fw=$OPTARG;;
      r) # 
         Rv=$OPTARG;;
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
if [[ -z "$PATH_fastQ" ]] || [[ -z "$PATH_output" ]] || [[ -z "$genome_size" ]] || [[ -z "$cov" ]]
then
	echo "Please provide all required arguments (-i PATH_fastQ, -o PATH_output, -g genome_size, -d cov )! use starter_subsampling.sh -h for help on syntax"
	exit
fi

###############################################################################CODE#################################################################################
#Remove previous files
#rm $PATH_output/failed.txt
#rm $PATH_output/SampleSet_readstats.txt

###Create folders###
mkdir -p $PATH_output
#mkdir -p $PATH_tmp

###Activate conda environment###

eval "$(conda shell.bash hook)"
conda activate $conda_env

###Create info file###

date > $PATH_output/info.txt
echo "Version script: "$version >> $PATH_output/info.txt
#echo "seqtk version: "$(seqtk --version) >> $PATH_output/info.txt #Does not work
echo "Input files: "$PATH_fastQ >> $PATH_output/info.txt
echo "Output files:"$PATH_output >> $PATH_output/info.txt
echo "Temporary directory: "$PATH_tmp >> $PATH_output/info.txt
echo "Amount of threads used: "$cpu >> $PATH_output/info.txt
echo "Sample set: "$set >> $PATH_output/info.txt
echo "Conda environment: "$conda_env >> $PATH_output/info.txt
echo "Amount of samples in input folder:" $(ls $PATH_fastQ/*$Fw$filetype | wc -l) >> $PATH_output/info.txt

#Make header of the summary file 
echo -e "Sample\tDesired_Coverage\tgenome_size\tTotal_bases_Fw\tTotal_bases_Rv\tTotal_bases\tEstimated_depth(x)\tTotal_bases_afterSubsampling_Fw\tTotal_bases_afterSubsampling_Rv\tTotal_bases_afterSubsampling\tEstimated_depth(x)_afterSubsampling" >> $PATH_output/$set"_readstats.txt"

#Loop through all the Fw raw fastQ files
for fastq in $PATH_fastQ/*$Fw$filetype
do
	SampleName=$(basename $fastq| cut -d '_' -f 1)
	Sample=$(basename $fastq)
	#read=$(basename $fastq| cut -d '.' -f 1 | rev | cut -d '_' -f 1 | rev)
	SampleName_Fwread=$SampleName"-subsampled"$Fw$filetype
	SampleName_Rvread=$SampleName"-subsampled"$Rv$filetype
	fastq_Rv=$(echo $fastq | sed "s/$Fw$filetype$/$Rv$filetype/1")
	Sample_Rv=$(basename $fastq_Rv)
	total_bases=0
	total_bases_Fw=0
	total_bases_Rv=0
	Depth_est=0
	Factor=0
	total_bases_subsample=0
	total_bases_subsample_Fw=0
	total_bases_subsample_Rv=0
	Depth_est_subsample=0
	
	if (([ -f "$PATH_output/$SampleName_Fwread" ] && [ -f "$PATH_output/$SampleName_Rvread" ]) || ([ -f "$PATH_output/$Sample" ] && [ -f "$PATH_output/$Sample_Rv" ]) )
	then
		 echo "Sample was already subsampled or copied" >> $PATH_output/AlreadyAnalyzed.txt
	else
		#total_bases=$(seqtk fqchk -q $Min_BQ $fastq | grep 'ALL' | cut -f 2) 
		total_bases_Fw=$(seqkit stats $fastq | tail -1 | tr -s " " | cut -d ' ' -f 5 | sed "s/,//g") #tr: to remove the consecutive spaces; sed to remove the commas in the number 
		total_bases_Rv=$(seqkit stats $fastq_Rv | tail -1 | tr -s " " | cut -d ' ' -f 5 | sed "s/,//g") #tr: to remove the consecutive spaces; sed to remove the commas in the number 
		total_bases=$(($total_bases_Fw + $total_bases_Rv))
		#echo $total_bases
		#echo $genome_size
		Depth_est=$(python -c "print((($total_bases)/$genome_size))") #Some reverse files gave lower average read length than fw file!
		Depth_est_r=$(printf "%.0f " $Depth_est)
		echo "Estimated depth:"$Depth_est_r
		if [[ "$Depth_est_r" -gt "$cov" ]]
		then 
			#Factor=$(python -c "print($cov/$Depth_est)")
			Factor=$(bc -l <<< $cov/$Depth_est)
			#echo $Factor
			#seqtk sample $fastq $Factor | pigz --fast -c -p $cpu > $PATH_output/$SampleName_read$filetype
			zcat $fastq | seqkit sample -p $Factor -s 11 -o $PATH_output/$SampleName_Fwread
			zcat $fastq_Rv | seqkit sample -p $Factor -s 11 -o $PATH_output/$SampleName_Rvread
			#total_bases_subsample=$(seqtk fqchk -q 3 $PATH_output/$SampleName_read$filetype |  grep 'ALL' | cut -f 2) #use base quality of 3 to calculate in that bases might be cut off by trimming step
			total_bases_subsample_Fw=$(seqkit stats $PATH_output/$SampleName_Fwread | tail -1 | tr -s " " | cut -d ' ' -f 5 | sed "s/,//g")
			total_bases_subsample_Rv=$(seqkit stats $PATH_output/$SampleName_Rvread | tail -1 | tr -s " " | cut -d ' ' -f 5 | sed "s/,//g")
			total_bases_subsample=$(($total_bases_subsample_Fw + $total_bases_subsample_Rv))
			Depth_est_subsample=$(python -c "print((($total_bases_subsample)/$genome_size))")
			Depth_est_subsample_r=$(printf "%.0f " $Depth_est_subsample)
		else 
			echo "No Need to Subsample"
			cp $fastq $PATH_output/
			cp $fastq_Rv $PATH_output/
			Depth_est_subsample_r=0
		fi
		paste --delimiter='\t'  <(echo $SampleName)	<(echo $cov) <(echo $genome_size) <(echo $total_bases_Fw) <(echo $total_bases_Rv) <(echo $total_bases) <(echo $Depth_est_r) <(echo $total_bases_subsample_Fw) <(echo $total_bases_subsample_Rv) <(echo $total_bases_subsample) <(echo $Depth_est_subsample_r)	>> $PATH_output/$set"_readstats.txt"
	fi
done

exit
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