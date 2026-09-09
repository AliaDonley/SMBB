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
module load minimap2
ASM=smb_hifiasm_default.bp.p_ctg.fasta  ##raw assembly (sequence only) fasta and fastq (sequence and quality score for every base)
READS=m84100_251120_201916_s3.hifi_reads.fastq
##just doing this once, commenting out mkdir after initial run
mkdir -p purge_dups_out
cd purge_dups_out
##Step 1: mapping HiFi reads back to the primary assembly
##minimap is an aligner that takes individual HiFi reads and finds assembly it best matches and reports that alignment
## -x map-hifi tells minimap to use parameters specific to pacbio hifi, using 24 threads for speed, and outputting into a compressed file for next step
minimap2 -x map-hifi -t 24 ../$ASM ../$READS | gzip -c > reads.paf.gz
##Step 2:Calculate coverage Stats and cutoffs
##pbcstat reads paf alignment and outputs a read depth histogram used in step 4
##calcuts takes hisogram and calcs coverage gutoff thresholds (normal single copy vs anything sus that could indicate duplicated region). done off depth distribution. 
pbcstat reads.paf.gz
calcuts PB.stat > cutoffs 2> calcuts.log
##Step 3: self align assembly to find duplicate regions
##split_fa breaks long stretches of assembly before self alignment to avoid artifacts from gap regions
##minimap-x asm5- used for assembly to assembly alignment rather than read to read. 5 indicates its tuned for sequences with up to ~5% divergence(most strict out of 5,10,20)
##DP (haha) Without D mm2 would report all sequences that matched itself (noise) and P reports every alignment chain found, including all ovelapping and redundant. Standard command for mm2
split_fa ../$ASM > asm.split.fasta
minimap2 -x asm5 -t 24 -DP asm.split.fasta asm.split.fasta | gzip -c > asm.split.self.paf.gz
##Step 4: identify dups
##T cutoffs feeds in coverage cutoffs from step 2. c PB base.cov does the same from step 2 (pbcstat second output)
##asm.split..etc feeds in self alignment from step 3
##2: a purge_dups flag indigating a two-pass/combined coverage and alignment code
purge_dups -2 -T cutoffs -c PB.base.cov asm.split.self.paf.gz > dups.bed 2> purge_dups.log
##output, dups.bed is a bedfile with contig name, start position, end position and classification)
##Step 5: extract the purged sequences
##takes dups.bed and plits it into two output files
#purged.fa-cleaned assembly with flagged duplicate regions removed. New candidate primary assembly
#hap.fa- sequences that got removed
get_seqs -e dups.bed ../$ASM
##outputs: purged.fa  and   hap.fa
