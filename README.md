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
  a. p_ctg (the primary contig), a mostly happloid rep of genome hifiasm outputs where it has         tried to merge the two haplotypes into one consensus sequence per genomic region. 
  b. hap1/hap2 (a_ctg in older versions) are the phased haplotype assemblies. Hifiasms attempt to     keep each parental hap. separate rather than combining. 

  Using BUSCO (Benchmarking Universal Single Copy Orthologs) to check the assembly for completeness. 

--------------------------------------------------
	|Results from dataset lepidoptera_odb10           |
	--------------------------------------------------
	|C:90.3%[S:78.4%,D:11.9%],F:2.9%,M:6.8%,n:5286    |
	|4771	Complete BUSCOs (C)                       |
	|4144	Complete and single-copy BUSCOs (S)       |
	|627	Complete and duplicated BUSCOs (D)        |
	|153	Fragmented BUSCOs (F)                     |
	|362	Missing BUSCOs (M)                        |
	|5286	Total BUSCO groups searched               |
	--------------------------------------------------

p_ctg has actual unresolved haplo duplication then. Going to try purging duplicates. Identifying contigs or portion of the contigs that are redundant and removing them. 

Going to follow these steps:
  a. Map HiFi reads back to primary assembly using minimap2, getting read-depth coverage across contigs
  b. calculate coverage stats and cutoffs using pbcstat and calcuts. This step identifies coverage thresholds that seperate typical single copy regions from too high coverage duplicate regions
  c. self align the assembly against itself using split_fa and minimap2. Will find contigs/regions that are near duplicates of eachother 
  d. Run purge_dups to combine the coverage singal and self alignment signal to flag duplicate and redundant sequences 
  e. Get rid of purged sequences with get_seqs to produce final, cleaned up primary assembly and a seperate file of what actually got removed. 

References for this stuff:
  a. https://pmc.ncbi.nlm.nih.gov/articles/PMC7203741/


Something worth noting from a github and discussion page
  a. This workflow works really good with Hifiasm, but not as well with IPA and Flye assemblies
  b. Evaluate the purged assembly with Busco afterwards. Make sure you didn't over correct. Watch to make sure the Complete (C) percentage doesn't drop even as Duplicated (D) falls. 


  
  
