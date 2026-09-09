# SMBB

/uufs/chpc.utah.edu/common/home/gompert-group2/data/sandmountain_blue

# Reference Genome
Raw data in /uufs/chpc.utah.edu/common/home/u6047808/sandmountain_blue/ReferenceGenome/genome_e_pallescens

## Decided to use Hifiasm to assemble the Pacbio sequence data from BYU Genomics Core. We have HiFi (CCS, high-accuracy) data. 

Hifiasm: https://genpipes.readthedocs.io/en/genpipes-v-3.6.2/user_guide/pipelines/gp_pacbio.html

Ran hifiasm.sh with sbatch to get the 3 outputs:
  a. smb_hifiasm_default.bp.p_ctg.fasta
  b. smb_hifiasm_default.bp.hap1.p_ctg.fasta
  c. smb_hifiasm_default.bp.hap2.p_ctg.fasta


## Check contents and size of outputs with
seqkit stats smb_hifiasm_default.bp.p_ctg.fasta smb_hifiasm_default.bp.hap1.p_ctg.fasta smb_hifiasm_default.bp.hap2.p_ctg.fasta



The Hifiasm assembly looked odd. 
  a. p_ctg (the primary contig), a mostly happloid rep of genome hifiasm outputs where it has tried to merge the two haplotypes into one consensus sequence per genomic region. 
  b. hap1/hap2 (a_ctg in older versions) are the phased haplotype assemblies. Hifiasms attempt to keep each parental hap. separate rather than combining. 

  
