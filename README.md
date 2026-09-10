# SMBB

/uufs/chpc.utah.edu/common/home/gompert-group2/data/sandmountain_blue

# Reference Genome
Raw data in /uufs/chpc.utah.edu/common/home/u6047808/sandmountain_blue/ReferenceGenome/genome_e_pallescens

## Decided to use Hifiasm to assemble the Pacbio sequence data from BYU Genomics Core. We have HiFi (CCS, high-accuracy) data. 
Hifiasm: https://genpipes.readthedocs.io/en/genpipes-v-3.6.2/user_guide/pipelines/gp_pacbio.html

## Ran hifiasm.sh with sbatch 
```sh
#!/bin/sh
#SBATCH --time=240:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --mem=200G
#SBATCH --account=gompert-np
#SBATCH --partition=gompert-np
#SBATCH --job-name=hifiasm
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=alia.donley@usu.edu
cd /uufs/chpc.utah.edu/common/home/u6047808/sandmountain_blue/ReferenceGenome

~/bin/hifiasm \
        -t 24 \
        -o smb_hifiasm_default \
        m84100_251120_201916_s3.hifi_reads.fastq

# Convert primary contig gfa to fasta right after, so success is verifiable in one job
awk '/^S/{print ">"$2"\n"$3}' smb_hifiasm_default.bp.p_ctg.gfa > smb_hifiasm_default.bp.p_ctg.fasta
awk '/^S/{print ">"$2"\n"$3}' smb_hifiasm_default.bp.hap1.p_ctg.gfa > smb_hifiasm_default.bp.hap1.p_ctg.fasta
awk '/^S/{print ">"$2"\n"$3}' smb_hifiasm_default.bp.hap2.p_ctg.gfa > smb_hifiasm_default.bp.hap2.p_ctg.fasta
```

To get the 3 outputs:
  a. smb_hifiasm_default.bp.p_ctg.fasta
  b. smb_hifiasm_default.bp.hap1.p_ctg.fasta
  c. smb_hifiasm_default.bp.hap2.p_ctg.fasta

### Check contents and size of outputs 
with: seqkit stats smb_hifiasm_default.bp.p_ctg.fasta smb_hifiasm_default.bp.hap1.p_ctg.fasta smb_hifiasm_default.bp.hap2.p_ctg.fasta

The Hifiasm assembly looked odd. 
  a. p_ctg (the primary contig), a mostly happloid rep of genome hifiasm outputs where it has tried to merge the two haplotypes into one consensus sequence per genomic region. 
  b. hap1/hap2 (a_ctg in older versions) are the phased haplotype assemblies. Hifiasms attempt to keep each parental hap. separate rather than combining. 

## BUSCO
Using BUSCO (Benchmarking Universal Single Copy Orthologs) to check the assembly for completeness. Downloaded the lepidoptera_odb10 data set and put the path in my shell script so I could use it offline on my interactive node. 

## Ran busco.sh with sbatch
busco.sh
```sh
#!/bin/sh
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --mem=64G
#SBATCH --account=gompert-np
#SBATCH --partition=gompert-np
#SBATCH --job-name=busco_pctg
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=alia.donley@usu.edu

cd /uufs/chpc.utah.edu/common/home/u6047808/sandmountain_blue/ReferenceGenome

module load busco

busco -i smb_hifiasm_default.bp.p_ctg.fasta \
      -l lepidoptera_odb10 \
      -o busco_p_ctg \
      -m genome \
      -c 24 \
      --offline \
      --download_path /uufs/chpc.utah.edu/common/home/u6047808/sandmountain_blue/ReferenceGenome/busco_downloads
```

Output: table as an output and direcotry with logs in busco_p_ctg
```
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
```
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


## Purging

set up purge_dups to fix the duplication error we think we're seeing. Used minimap 2 and a conda environment for genome assembly. Detailed notes on this can be found written into the actual script above. Bare bone notes below in 

purge_dups.sh
```sh
#!/bin/sh
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --mem=64G
#SBATCH --account=gompert-np
#SBATCH --partition=gompert-np
#SBATCH --job-name=purge_dups
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=alia.donley@usu.edu

cd /uufs/chpc.utah.edu/common/home/u6047808/sandmountain_blue/ReferenceGenome

source ~/miniforge3/etc/profile.d/conda.sh
conda activate genome_assembly
module load minimap2   # if not also installed in the conda env

ASM=smb_hifiasm_default.bp.p_ctg.fasta
READS=m84100_251120_201916_s3.hifi_reads.fastq

mkdir -p purge_dups_out
cd purge_dups_out

# Step 1: map HiFi reads back to the primary assembly
minimap2 -x map-hifi -t 24 ../$ASM ../$READS | gzip -c > reads.paf.gz

# Step 2: calculate coverage stats and cutoffs
pbcstat reads.paf.gz
calcuts PB.stat > cutoffs 2> calcuts.log

# Step 3: self-align the assembly to find duplicate regions
split_fa ../$ASM > asm.split.fasta
minimap2 -x asm5 -t 24 -DP asm.split.fasta asm.split.fasta | gzip -c > asm.split.self.paf.gz

# Step 4: identify duplicates
purge_dups -2 -T cutoffs -c PB.base.cov asm.split.self.paf.gz > dups.bed 2> purge_dups.log

# Step 5: extract the purged (cleaned) sequences
get_seqs -e dups.bed ../$ASM
```
 Results are as follows (seqkit stats purge_dups_out/purged.fa purge_dups_out/hap.fa)
 ```
 file                      format  type  num_seqs      sum_len  min_len   avg_len  max_len
purge_dups_out/purged.fa  FASTA   DNA     11,108  574,738,915    5,055    51,741  748,165
purge_dups_out/hap.fa     FASTA   DNA      4,665  171,620,155    5,784  36,788.9  584,241
```

Rerun BUSCO on purged files using busco_purged.sh to confirm the Duplicated (D) dripped from the origional 11.9% and the Complete (C) did not trop much from the original 90.3%. 

busco_purged.sh
```sh
#!/bin/sh
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks=24
#SBATCH --mem=64G
#SBATCH --account=gompert-np
#SBATCH --partition=gompert-np
#SBATCH --job-name=busco_purged
#SBATCH --mail-type=FAIL,END
#SBATCH --mail-user=alia.donley@usu.edu

cd /uufs/chpc.utah.edu/common/home/u6047808/sandmountain_blue/ReferenceGenome

module load busco

busco -i purge_dups_out/purged.fa \
      -l lepidoptera_odb10 \
      -o busco_purged \
      -m genome \
      -c 24 \
      -f \
      --offline \
      --download_path /uufs/chpc.utah.edu/common/home/u6047808/sandmountain_blue/ReferenceGenome/busco_downloads
```


  
