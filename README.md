<p align="center">
  <img src="logo/ntmseq_logo.svg" alt="NTMseq logo" width="900">
</p>

# NTMseq
This repository contains NTMseq, a comprehensive bioinformatics pipeline for the analysis of whole-genome sequencing data from non-tuberculous mycobacteria (NTM), including quality control, taxonomic classification, assembly, approximate phylogenetic analysis, plasmid and (drug) resistance analysis.

For Research use only. Not for use in diagnostic procedures. 

### Requirements
- Linux-based system (preferably not WSL on Windows as some tools might not be compatible)
- Basic command-line experience
- Conda (Miniconda or Anaconda)

### Modules ###

1.	Quality control of raw sequence reads
	
[Input: FastQ files; Required tools: FastQC and multiQC]

2.	Preprocessing of raw sequence reads (e.g. adapter removal)

[Input: FastQ files; Required tools: fastp]

2.	Contamination detection
   
[Input: FastQ files or FastA files; Required tools: kraken2 + krona; Required database: kraken2 + krona]

3. Multi-locus sequence typing (MLST)
   
[Input: FastQ files; Required tools: SRST2; Required database: pubMLST (automatic download)]

4. NTM (sub)species and resistance prediction

[Input: FastQ/FastA files; Required tools: NTMprofiler; Required database: ntm-db]

5.	Assembly of short-read illumina sequencing data
    
[Input: FastQ files; Required tools: Shovill; Output: FastA files]

6.	Fast phylogenetic analysis using Mashtree

[Input: FastQ files or FastA files; Required tools: Mashtree]

7.	Detection of known plasmids

[Input: FastQ files; Required tools: SRST2 and seqkit; Required database: PLSDB or custom]

8.	De novo prediction of plasmid contigs

[Input: FastQ files; Required tools: plasmidspades]

[Input: FastA files; Required tools: platon; Required database: platon]

9.	Resistance and virulence gene prediction

[Input: FastA files; Required tools: AMRfinder+ and database]

[Input: FastA files; Required tools: abricate and database - vfdb by default]


### Setup

**1. Download the repository**

mkdir NTMseq

cd NTMseq

wget https://github.com/ngs-fzb/NTMseq/archive/refs/heads/main.tar.gz && tar -xzf main.tar.gz

rm main.tar.gz

**2. Run the installation script**

cd /NTMseq-main/installation 

bash installation_NTMseq.sh

Note: This will create separate conda environments for each tool used in the pipeline.
Note: Specific tool versions are defined in the script. If you choose to use newer versions, you may need to update the conda environment accordingly. However, there is no guarantee that the pipeline will still function correctly.

**3. Download required databases**
   
⚠️ Note: Some databases are large (>50 GB) and must be downloaded in a location with enough storage space.

_Taxonomy_

1. Kraken 2: [https://benlangmead.github.io/aws-indexes/k2] --> choose your preferred database, depending on the space you have available
   
TLDR: wget https://genome-idx.s3.amazonaws.com/kraken/k2_pluspf_16_GB_20260226.tar.gz && tar -xvzf k2_pluspf_16_GB_20260226.tar.gz

3. Krona: [https://github.com/marbl/Krona/wiki/KronaTools]

TLDR: conda run -n NTMseq_kraken2 ktUpdateTaxonomy.sh /path/to/krona-db

_Typing_

1. MLST via SRST2: [https://github.com/katholt/srst2]

This database is updated automatically when running the pipeline. However, due to a recent change in data access policy at pubMLST [https://pubmlst.org/change-data-access-policy], only ST types and profiles submitted up to December 2024 will be reported. For the newest ST types, please submit your assemblies directly to the pubMLST website, after login.
Currently, MLST typing is only available for _M. abscessus_

_Resistance prediction_

1. NTM-Profiler: [https://github.com/jodyphelan/NTM-Profiler]

TLDR: conda run -n NTMseq_NTMprofiler ntm-profiler update_db

3. AMRFinder: [https://github.com/ncbi/amr/wiki/Upgrading#database-updates]

TLDR: conda run -n NTMseq_NTMprofiler amrfinder_update -d </database_directory>

_Plasmid prediction_

1. Custom plasmid database: [https://ccb-microbe.cs.uni-saarland.de/plsdb/plasmids/]

You can download the full PLSDB plasmids database or a subset thereof (e.g. only those of mycobacteriaceae) via API. You will need to create multi-fasta file containing all plasmids.

Alternatively, use the pre-downloaded multi-fasta file of 208 mycobacteriaceae plasmids that can be found in this repository (db folder): 2023_11_03_v2_PLSDB_mycobacteriaceae_208plasmids.fasta

Optional:

2. Platon: [https://zenodo.org/search?page=1&size=20&q=conceptrecid:3349651&all_versions&sort=-version] or [https://github.com/oschwengers/platon#database]

### Usage

1. Configure your analysis in:
   
config/config_NTMseq.txt

(e.g. paths to FASTQ files, databases, output directory, analyses you want to do)

Run the pipeline:

bash /scripts/starter_NTMseq.sh config/config_NTMseq.txt

### Help

Do you need help or have feature requests? Just drop me a mail @ mdiricks@fz-borstel.de

### Citation

Paper in progress...
Please use this github page as temporary reference.
