library(polysat)
#Input (distance matrix, e.g. output from mash)
File <- "//my-thecus6/Thecus_SeqData/NTMseq_mdiricks/Mabscessus/PLSDB_SRST2/M-200_D-80_C-40/Plasmid_hits/Mashtree/SampleSet/distance"
matrix <- read.table (File, sep="\t", header=TRUE)
rn <- matrix[,1]
matrix_g <- matrix [,-1]
rownames(matrix_g) <- rn
groupings_0.5 <- assignClones(matrix_g, threshold=0.5)
groupings_0.3 <- assignClones(matrix_g, threshold=0.3)
groupings_0.1 <- assignClones(matrix_g, threshold=0.1)
groupings_0.01 <- assignClones(matrix_g, threshold=0.01)
#Output (csv files with names of samples included in matrix and their grouping)
write.table(groupings_0.5,"//my-thecus6/Thecus_SeqData/NTMseq_mdiricks/Mabscessus/PLSDB_SRST2/M-200_D-80_C-40/Plasmid_hits/Mashtree/SampleSet/Grouping_0.5.csv",sep=",")
write.table(groupings_0.3,"//my-thecus6/Thecus_SeqData/NTMseq_mdiricks/Mabscessus/PLSDB_SRST2/M-200_D-80_C-40/Plasmid_hits/Mashtree/SampleSet/Grouping_0.3.csv",sep=",")
write.table(groupings_0.1,"//my-thecus6/Thecus_SeqData/NTMseq_mdiricks/Mabscessus/PLSDB_SRST2/M-200_D-80_C-40/Plasmid_hits/Mashtree/SampleSet/Grouping_0.1.csv",sep=",")
write.table(groupings_0.01,"//my-thecus6/Thecus_SeqData/NTMseq_mdiricks/Mabscessus/PLSDB_SRST2/M-200_D-80_C-40/Plasmid_hits/Mashtree/SampleSet/Grouping_0.01.csv",sep=",")
