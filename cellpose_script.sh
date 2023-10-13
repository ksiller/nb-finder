#!/usr/bin/env bash

#SBATCH -J cellpose # A single job name for the array
#SBATCH --ntasks-per-node=10 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 0:30:00 ### 15 seconds
#SBATCH --mem 64G
#SBATCH -o /scratch/aob2x/logs/demo_1.%A_%a.out # Standard output
#SBATCH -e /scratch/aob2x/logs/demo_1.%A_%a.err # Standard error
#SBATCH -p gpu
#SBATCH --gres=gpu
#SBATCH --account berglandlab

### run as: sbatch --array=2 PATH_TO_THIS_FILE
### sacct -j XXXXXXXXX
### cat /scratch/tn6a/logs/demo_1.*.err
# ijob -A berglandlab -c10 -p gpu --mem=64G --gres=gpu

### load modules
  module load fiji/1.53t
  module load anaconda/2020.11-py3.8 parallel/20200322
  module load gcc/9.2.0 openmpi/3.1.6 R/4.2.1

### repository path
  repo_path=/home/aob2x/nb-finder

## set up RAM disk
  ### SLURM_JOB_ID=1
  [ ! -d /dev/shm/$USER/ ] && mkdir /dev/shm/$USER/
  [ ! -d /dev/shm/$USER/${SLURM_JOB_ID} ] && mkdir /dev/shm/$USER/${SLURM_JOB_ID}
  tmpdir=/dev/shm/$USER/${SLURM_JOB_ID}

  echo "Temp dir is $tmpdir"


### specify parameters
  iter=2
  FLOW_THRESHOLD=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${iter}q;d" | cut -f1 -d',' )
  CELLPROB_THRESHOLD=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${iter}q;d" | cut -f2 -d',' )
  ANISOTROPY=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${iter}q;d" | cut -f3 -d',' )
  medianxy=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${iter}q;d" | cut -f4 -d',' )
  medianz=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${iter}q;d" | cut -f5 -d',' )

  img_file=/scratch/aob2x/cellpose_output/me10247.animal9.tif
  img_stem=$( echo ${img_file} | rev | cut -f1 -d'/' | rev | sed 's/.tif//g' )

  output_path=${tmpdir}
  output_file=${output_path}/${img_stem}.${medianxy}.${medianz}.${FLOW_THRESHOLD}.${CELLPROB_THRESHOLD}.${ANISOTROPY}.tif
  ls -lh ${img_file}
  echo $output_file

  params_template='outputdir="OUTPUT",imgfile="INPUT",outputfile="FILE",nucleiCh=3,membraneCh=1,medianXY="xy",medianZ="z",adjust="True",show="False"'
  params_template_1=$( echo ${params_template} | sed "s|OUTPUT|${output_path}|g" )
  params_template_2=$( echo ${params_template_1} | sed "s|INPUT|${img_file}|g" )
  params_template_3=$( echo ${params_template_2} | sed "s|FILE|${output_file}|g" )
  params_template_4=$( echo ${params_template_3} | sed "s|xy|${medianxy}|g" )
  params_template_5=$( echo ${params_template_4} | sed "s|z|${medianz}|g" )

  echo ${params_template_5}

### first run NB_preprocess
  ImageJ-linux64 --headless --ij2 --mem=64G --run /home/aob2x/nb-finder/NB_Preprocess.py $params_template_5

### run cellpose
  source activate cellpose

  NB_output_file=$( echo ${output_file} | sed 's/\.tif/-NB.tif/g' )

  cellpose \
  --image_path ${NB_output_file} \
  --save_tif --save_txt --verbose --do_3D --save_outlines \
  --use_gpu \
  --do_3D \
  --pretrained_model nuclei \
  --diameter 30 \
  --chan 0 \
  --flow_threshold 0.4 \
  --cellprob_threshold 0.5 \
  --anisotropy 0.5

### parse cellpose
  cellpose_output_file=$( echo ${NB_output_file} | sed 's/\.tif/-NB_seg.npy/g' )
  Rscript --vanilla ${repo_path}/NB_parse.R ${output_file}-NB_seg.npy

### save results and clean up
  
