# Overview

The NB_Preprocess.py script is a plugin for Fiji/ImageJ to aid in the preprocessing of multi-channel volumetric confocal images to identify the position of cells using nuclei markers.

**Optional;** The plugin can utilize membrane markers in additional channels to aid in the demarkation of neighboring nuclei. See below.

# Prerequisites

In order to use the plugin, you will need the Fij application (available here https://imagej.net/software/fiji/) and a functional conda command to install the Cellpose environmnt

## Cellpose installation
```
git clone https://github.com/ksiller/nb-finder.git
cd nbfinder
conda create -f environment.yaml 
```

# Fiji Plugin installation

1. Start Fiji.

2. In Fiji, go to Plugins > Install….

3. In the first pop-up dialog browse to and select the `NB_Preprocess` script. Click Open.

4. In the second dialog window, select the plugins directory (or a subdirectory within plugins) to where the script should be installed. Click Save.

5. After installing the script as plugin, restart Fiji.

6. In Fiji, go to File > Plugins and verify that the script is available. The _ (underscore) and file extension are stripped from the plugin name.

# Batch processing of image files from the command line

## MacOS

Before running the plugin, ensure that the JAVA_HOME environment variable is set to point to a functional Java Runtime Environment (JRE), version 1.8. E.g.
```
export JAVA_HOME=/Applications/Fiji.app/java/macosx/jdk1.8.0_172.jre/jre/  # verify the specific path on your computer
```

Then run:
```
ImageJ-macosx --headless --ij2 --run nb-finder/NB_Preprocess.py 'outputDir="/Users/khs3z/Desktop/",imgfile="lobe1.tif",nucleiCh=3,membraneCh=1,medianXY=3.000000,medianZ=2.000000,adjust="True",show="False"'

source activate cellpose
cellpose --image_path lobe1-NB.tif --use_gpu --do_3D --save_tif --pretrained_model nuclei --diameter 30 --chan 0 --verbose
```

## Linux

Before running the plugin, ensure that the JAVA_HOME environment variable is set to point to a functional Java Runtime Environment (JRE), version 1.8.

This is a Slurm job script to run the 2-step processing on a GPU device in an HPC environment. The `imgfile` and `image_path` command line options should be adjusted to reflect the particular image files.

```
#!/bin/bash
#SBATCH -A <your_allocation>
#SBATCH -p gpu
#SBATCH --gres=gpu
#SBATCH -c 16
#SBATCH --mem=64G
#SBATCH -t 1:00:00

# Fiji preprocessing
module load java
ImageJ-linux64 --headless --ij2 --mem=64G --run nb-finder/NB_Preprocess.py 'outputDir="output",imgfile="lobe1.tif",nucleiCh=3,membraneCh=1,medianXY=3.000000,medianZ=2.000000,adjust="True",show="False"'
# this will create a lobe1-NB.tif file with the segmentation mask

# Cellpose
module load anaconda
source activate cellpose
cellpose --image_path lobe1-NB.tif --use_gpu --do_3D --save_tif --pretrained_model nuclei --diameter 30 --chan 0 --verbose
```

Additional parameters may need to be adjusted for your particular use case.
