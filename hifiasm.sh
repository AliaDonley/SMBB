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
