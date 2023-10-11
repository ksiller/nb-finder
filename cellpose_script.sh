#!/usr/bin/env bash



#SBATCH -J runFASTQC # A single job name for the array
#SBATCH --ntasks-per-node=10 # one core
#SBATCH -N 1 # on one node
#SBATCH -t 0:30:00 ### 15 seconds
#SBATCH --mem 64G
#SBATCH -o /scratch/tn6a/logs/demo_1.%A_%a.out # Standard output
#SBATCH -e /scratch/tn6a/logs/demo_1.%A_%a.err # Standard error
#SBATCH -p gpu
#SBATCH --account biol4559-aob2x
#SBATCH --array 1-4

### run as: sbatch --array=2 PATH_TO_THIS_FILE
### sacct -j XXXXXXXXX
### cat /scratch/tn6a/logs/demo_1.*.err


#fiji script
output_path=/scratch/tn6a/test_tifs
#img_file=/standard/vol191/siegristlab/Taylor/processed.in.cellpose/test_process_tiffs/me10247.animal9.tif
medianxy=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${SLURM_ARRAY_TASK_ID}q;d" | cut -f4 -d',' )
medianz=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${SLURM_ARRAY_TASK_ID}q;d" | cut -f5 -d',' )
output_file=${img_file}_${FLOW_THRESHOLD}_${CELLPROB_THRESHOLD}_${ANISOTROPY}_${medianxy}_${medianz}


params_template='outputdir="OUTPUT",imgfile="INPUT",outputfile="FILE",nucleiCh=3,membraneCh=1,medianXY="xy",medianZ="z",adjust="True",show="False"'
params_template_1=$( echo ${params_template} | sed "s|OUTPUT|${output_path}|g" )
params_template_2=$( echo ${params_template_1} | sed "s|INPUT|${img_file}|g" )
params_template_3=$( echo ${params_template_2} | sed "s|FILE|${output_file}|g" )
params_template_4=$( echo ${params_template_3} | sed "s|xy|${medianxy}|g" )
params_template_5=$( echo ${params_template_4} | sed "s|z|${medianz}|g" )




#imgfile=/standard/vol191/siegristlab/Taylor/processed.in.cellpose/test_process_tiffs/me1047.animal6.tif
module load fiji
ImageJ-linux64 --headless --ij2 --mem=64G --run /home/tn6a/nb-finder/NB_Preprocess.py echo $params_template_4

echo "this is job: "
echo ${SLURM_ARRAY_TASK_ID}

FLOW_THRESHOLD=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${SLURM_ARRAY_TASK_ID}q;d" | cut -f1 -d',' )
CELLPROB_THRESHOLD=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${SLURM_ARRAY_TASK_ID}q;d" | cut -f2 -d',' )
ANISOTROPY=$( cat /standard/vol191/siegristlab/Taylor/settings.table.csv | sed "${SLURM_ARRAY_TASK_ID}q;d" | cut -f3 -d',' )
#imageoutput
#imageinput




#Fiji preprocessing


#output tiff from preprocessing becomes input for cellpose

module load anaconda parallel
source activate cellpose

runCellPose() {
  cellpose \
  --image_path output_file\
  --save_tif --save_txt --verbose --do_3D \
  --use_gpu \
  --do_3D \
  --pretrained_model nuclei \
 --diameter 30 \
 --chan 0 \
  --flow_threshold 0.4 \
  --cellprob_threshold 0.5 \
  --anisotropy 0.5
}
export -f runCellPose

parallel -j10 ::: $( ls -d /standard/vol191/siegristlab/Taylor/processed.in.cellpose/test_process_tiffs/ | head -n1 )


 


