#!/usr/bin/env bash

#SBATCH -J cellpose # A single job name for the array
#SBATCH -t 0:15:00 ### 15 seconds
#SBATCH --mem 64G
#SBATCH -c 16
#SBATCH -o /standard/vol191/siegristlab/Taylor/logs/demo_1.%A_%a.out # Standard output
#SBATCH -e /standard/vol191/siegristlab/Taylor/logs/demo_1.%A_%a.err # Standard error
#SBATCH -p gpu
#SBATCH --gres=gpu
#SBATCH --account berglandlab

### run as: sbatch --array=2-2187 ~/nb-finder/cellpose_script.v2.sh
### sacct -j 54728273
### cat /standard/vol191/siegristlab/Taylor/logs/demo_1.54728273_1.err
# ijob -A berglandlab -c16 -p gpu --mem=64G --gres=gpu
### SLURM_ARRAY_TASK_ID=2

### load modules
  module load fiji/1.53t
  module load anaconda/2020.11-py3.8 parallel/20200322
  module load gcc/9.2.0 openmpi/3.1.6 R/4.2.1
  source activate cellpose

### path path
  repo_path=/standard/vol191/siegristlab/Taylor/nb-finder
  results_path=/standard/vol191/siegristlab/Taylor/aob_cellpose_results_2/

## set up tmpdir
  tmpdir=/scratch/tn6a/aob_cellpose_results

### function
  runCellpose() {
      ### specify parameters
        iter=${1} # iter=2
        FLOW_THRESHOLD=$( cat /standard/vol191/siegristlab/Taylor/settings.table.2.csv | sed "${iter}q;d" | cut -f1 -d',' )
        CELLPROB_THRESHOLD=$( cat /standard/vol191/siegristlab/Taylor/settings.table.2.csv | sed "${iter}q;d" | cut -f2 -d',' )
        STITCH_THRESHOLD=$( cat /standard/vol191/siegristlab/Taylor/settings.table.2.csv | sed "${iter}q;d" | cut -f3 -d',' )
        medianxy=$( cat /standard/vol191/siegristlab/Taylor/settings.table.2.csv | sed "${iter}q;d" | cut -f4 -d',' )
        medianz=$( cat /standard/vol191/siegristlab/Taylor/settings.table.2.csv | sed "${iter}q;d" | cut -f5 -d',' )

        img_file=$( cat /standard/vol191/siegristlab/Taylor/settings.table.2.csv | sed "${iter}q;d" | cut -f6 -d',' )
        img_stem=$( echo ${img_file} | rev | cut -f1 -d'/' | rev | sed 's/.tif//g' )

        output_path=${2} # output_path=$tmpdir
        output_file=${output_path}/${img_stem}.${medianxy}.${medianz}.${FLOW_THRESHOLD}.${CELLPROB_THRESHOLD}.${STITCH_THRESHOLD}.tif
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
        ImageJ-linux64 --headless --ij2 --mem=60G --run /standard/vol191/siegristlab/Taylor/nb-finder/NB_Preprocess.py $params_template_5

      ### run cellpose

        NB_output_file=$( echo ${output_file} | sed 's/\.tif/-NB.tif/g' )

        cellpose \
        --image_path ${NB_output_file} \
        --save_tif --do_3D \
        --use_gpu \
        --do_3D \
        --pretrained_model nuclei \
        --diameter 30 \
        --chan 0 \
        --flow_threshold ${FLOW_THRESHOLD} \
        --cellprob_threshold ${CELLPROB_THRESHOLD} \
        --stitch_threshold ${STITCH_THRESHOLD} \
        --anisotropy 5

      ### parse cellpose
        repo_path=${3} #
        # NB_output_file=/scratch/tn6a/aob_cellpose_results/me10247.animal10.0.0.0.0.0-NB.tif

        cellpose_output_file=$( echo ${NB_output_file} | sed 's/\.tif/_seg.npy/g' )
        ls -lhd $cellpose_output_file

        Rscript --vanilla ${repo_path}/NB_parse.R ${cellpose_output_file}

        #cat ${cellpose_output_file}.nMasks | sed "s/$/,${medianxy},${medianz},${FLOW_THRESHOLD},${CELLPROB_THRESHOLD},${ANISOTROPY}/g" > ${cellpose_output_file}.nMasks

        echo "Results are:"
        cat ${cellpose_output_file}.nMasks

      ### clean up
        ls -lha ${cellpose_output_file}
        cellpose_output_tiff=$( echo ${NB_output_file} | sed 's/\.tif/_cp_masks.tif/g' )
        #merge mask file with original file
        composite_file=$( echo ${NB_output_file} | sed 's/\.tif/composite.tif/g' )
        ImageJ-linux64 --headless --ij2 --mem=60G --run /standard/vol191/siegristlab/Taylor/nb-finder/Merge_Images.py $NB_output_file $cellpose_output_tiff $composite_file
        ls -lhd $cellpose_output_file
        ls -lhd $cellpose_output_tiff

        cp ${cellpose_output_file}.nMasks ${results_path}
        cp $cellpose_output_tiff ${results_path}
        cp $composite_file ${results_path}

        # rm ${cellpose_output_file}
        # rm ${NB_output_file}
        # rm ${cellpose_output_tiff}

  }
  export -f runCellpose

### run cellpose
    runCellpose ${SLURM_ARRAY_TASK_ID} ${tmpdir} ${repo_path}
