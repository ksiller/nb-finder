# Overview

The NB_Preprocess.py script is a plugin for Fiji/ImageJ to aid in the preprocessing of multi-channel volumetric confocal images to identify the position of cells using nuclei markers.

**Optional;** The plugin can utilize membrane markers in additional channels to aid in the demarkation of neighboring nuclei. See below.

# Prerequisites

In order to use the plugin, download and install the Fij application (available here https://imagej.net/software/fiji/).

# Plugin installation

1. Download the source code by either cloning this repository: git clone https://github.com/ksiller/aisanalyzer.git, or alternatively download and unpack the zip archive of this repository.

2. Start Fiji.

3. In Fiji, go to Plugins > Install….

4. In the first pop-up dialog browse to and select the AIS_Analysis.py script. Click Open.

5. In the second dialog window, select the plugins directory (or a subdirectory within plugins) to where the script should be installed. Click Save.

6. After installing the script as plugin, restart Fiji.

7. In Fiji, go to File > Plugins and verify that the script is available. The _ (underscore) and file extension are stripped from the plugin name.

# Interactive processing of single files (Fiji Graphical User Interface)

# Batch processing of image files from the command line

## MacOS

Before running the plugin, ensure that the JAVA_HOME environment variable is set to point to a functional Java Runtime Environment (JRE), version 1.8. E.g.
```
export JAVA_HOME=/Applications/Fiji.app/java/macosx/jdk1.8.0_172.jre/jre/  # verify the specific path on your computer
```

Then run:
```
ImageJ-macosx --headless --ij2 --run ../nb-finder/NB_Preprocess.py 'outputDir="/Users/khs3z/Desktop/",imgfile="lobe1.tif",nucleiCh=3,membraneCh=1,medianXY=3.000000,medianZ=2.000000,adjust="True",show="False"'
```

## Linux

Before running the plugin, ensure that the JAVA_HOME environment variable is set to point to a functional Java Runtime Environment (JRE), version 1.8.

Then run:
```
ImageJ-linux --headless --ij2 --run ../nb-finder/NB_Preprocess.py 'outputDir="/Users/khs3z/Desktop/",imgfile="lobe1.tif",nucleiCh=3,membraneCh=1,medianXY=3.000000,medianZ=2.000000,adjust="True",show="False"'
```

/Applications/Fiji.app/java/macosx/jdk1.8.0_172.jre/jre/ 
