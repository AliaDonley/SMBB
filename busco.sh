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
