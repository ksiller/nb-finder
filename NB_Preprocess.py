#@ File (label="Input image") imgfile
#@ File (label="Output directory", style="directory", required=False) outputdir
#@ String (label="Output file (optional)", style="file", required=False) outputfile
#@ Integer (label="Nuclei channel", min=1, max=7, value=1) nucleiCh
#@ Integer (label="Membrane channel", min=1, max=7, value=2) membraneCh
#@ Float (label="X-Y median filter", min=1.0, max=10.0, step=0.1, value=2.0) medianXY
#@ Float (label="Z median filter", min=1.0, max=10.0, step=0.1, value=3.0) medianZ
#@ Boolean (label="Adjust brightness", value=True) adjust
#@ Boolean (label="Show images", value=False) show
#@ LogService logger
#@ OUTPUT nucleiFile

from java.awt import GraphicsEnvironment
from java.lang import System
import os
from org.scijava.log import LogLevel
from ij import IJ, ImagePlus, ImageStack, Prefs, ImageJ
from ij import WindowManager
from ij.plugin import ImageCalculator, RGBStackMerge, ChannelSplitter, ZProjector
from ij.plugin.filter import ParticleAnalyzer
from jarray import array

if outputdir is None:
    outputdir = imgfile.getParent()
else:
    outputdir = outputdir.getAbsolutePath()
if outputfile is None or outputfile == "":
    outputfile = imgfile.getName()
    outputfile = outputfile[:outputfile.rindex(".")] + "-NB.tif"

if show and GraphicsEnvironment.isHeadless():
    show = False
    logger.log(LogLevel.INFO, 'Running headless, ignoring "show" option.')

# open image
inputimg = IJ.openImage(imgfile.getPath())                
logger.log(LogLevel.INFO, "Processing of %s" % imgfile.getPath())
logger.log(LogLevel.INFO, "nucleiCh=%d, membraneCh=%d, medianXY=%f, medianZ=%f, adjust=%s, show=%s" % (nucleiCh, membraneCh, medianXY, medianZ, adjust, show))
logger.log(LogLevel.INFO, "outputdir=%s" % outputdir)

# split and create copy of nuclei channel
channels = ChannelSplitter.split(inputimg)
nucleiCh = min(nucleiCh, len(channels))
nucleiImg = channels[nucleiCh-1].duplicate()

# enhance contrast
if adjust:
    for z in range(nucleiImg.getNSlices()):
        nucleiImg.setSlice(z+1)
        IJ.run(nucleiImg, "Enhance Contrast", "saturated=0.35")
        IJ.run(nucleiImg, "Apply LUT", "slice")

# apply filter to remoev noise
IJ.run(nucleiImg, "Median 3D...", "x=" + str(medianXY) + " y=" + str(medianXY) +" z=" + str(medianZ))

# optional
if membraneCh > 0 and membraneCh <= len(channels):
    membraneImg = channels[membraneCh-1].duplicate()
    IJ.run(membraneImg, "Despeckle", "stack")
    #membraneImg.setTitle(outputfile + "-Membrane.tif")
    #membraneFile = os.path.join(outputDir, membraneImg.getTitle())
    #logger.log(LogLevel.INFO, "Saving %s" % membraneFile)
    #IJ.saveAsTiff(membraneImg, membraneFile)
    #if show:
    #    membraneImg.show()
    nucleiImg = ImageCalculator.run(nucleiImg.duplicate(), membraneImg, "Subtract create 32-bit stack")
    IJ.run(nucleiImg, "Median 3D...", "x=" + str(medianXY) + " y=" + str(medianXY) +" z=" + str(medianZ))

# save and show
nucleiImg.setTitle(outputfile)
nucleiFile = os.path.join(outputdir, outputfile)
IJ.saveAsTiff(nucleiImg, nucleiFile)
if show:
    nucleiImg.show()
logger.log(LogLevel.INFO, "Saved %s" % os.path.join(outputdir, nucleiImg.getTitle()))

# clean up
if GraphicsEnvironment.isHeadless():
    os.system("kill %d" % os.getpid())

