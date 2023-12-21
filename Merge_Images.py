#@ File (label="Fluorescent image") imgfile
#@ File (label="Mask") maskfile
#@ File (label="Output directory", style="directory", required=False) outputdir
#@ String (label="Output file (optional)", style="file", required=False) outputfile
#@ String (label="Output image type", choices=["8-bit", "16-bit", "32-bit"], value="16-bit") convertBits
#@ Boolean (label="Show merged image", value=False) show
#@ LogService logger

import os
from java.awt import GraphicsEnvironment
from ij.plugin import RGBStackMerge, HyperStackConverter, RGBStackMerge
from ij import IJ, ImagePlus
from org.scijava.log import LogLevel
from loci.plugins import BF
from loci.plugins.in import ImporterOptions
import jarray.zeros


def open_hyperstack(fname):
    logger.log(LogLevel.INFO, "Opening %s" % fname)
    opts = ImporterOptions()
    opts.setId(fname)
    opts.setSplitChannels(True)
    colorImps = BF.openImagePlus(opts)
    return colorImps


def areCompatible(images):
    # use first image as reference
    width = images[0].getWidth()
    height = images[0].getHeight()
    slices = images[0].getNSlices()
    frames = images[0].getNFrames()
    # check that all have the same dimensions
    widthOK = all(item.getWidth() == width for item in images)
    heightOK = all(item.getHeight() == height for item in images)
    slicesOK = all(item.getNSlices() * item.getNFrames() == slices * frames for item in images)
    framesOK = all(item.getNFrames() * item.getNSlices() == frames * slices for item in images)
    logger.log(LogLevel.INFO, "Matched width: %s (%d)" %(widthOK, width))
    logger.log(LogLevel.INFO, "Matched height: %s (%d)" %(heightOK, height))
    logger.log(LogLevel.INFO, "Matched slices: %s (%d) %d" %(slicesOK, slices, images[-1].getNSlices()))
    logger.log(LogLevel.INFO, "Matched frames: %s (%d) %d" %(framesOK, frames, images[-1].getNFrames()))
    return widthOK and heightOK and slicesOK and framesOK


def merge (images, masks, convert):
    # create new array for all channels
    totalChannels = len(imgImps) + len(maskImps)
    channels = jarray.zeros(totalChannels, ImagePlus)
    for i in range(len(imgImps)):
        channels[i] = imgImps[i]
    for i in range(len(maskImps)):
        channels[i+len(imgImps)] = maskImps[i]
    # check compatibility of image channels    
    if areCompatible(channels):
    	# convert and merge channels
        logger.log(LogLevel.INFO, "Converting channels to %s" % convert)
        for c in channels:
            IJ.run(c, convert, "")
            logger.log(LogLevel.INFO, '\t' + c.getTitle())
        composite = RGBStackMerge.mergeChannels(channels, True)
        logger.log(LogLevel.INFO, "Completed merging")
    else:
        logger.log(LogLevel.INFO, "Images are not compatible. Aborting merging.")
        composite = None
    return composite


# main code block

if outputdir is None:
    outputdir = imgfile.getParent()
else:
    outputdir = outputdir.getAbsolutePath()
if outputfile is None or outputfile == "":
    outputfile = imgfile.getName()
    outputfile = outputfile[:outputfile.rindex(".")] + "-Overlay.tif"

if show and GraphicsEnvironment.isHeadless():
    show = False
    logger.log(LogLevel.INFO, 'Running headless, ignoring "show" option.')
    
# open and merge images
imgImps = open_hyperstack(imgfile.getAbsolutePath())
maskImps = open_hyperstack(maskfile.getAbsolutePath())
composite = merge(imgImps, maskImps, convertBits)

if composite is not None:
    # save and show merged composite image
    compositeFile = os.path.join(outputdir, outputfile)
    IJ.saveAsTiff(composite, compositeFile)
    logger.log(LogLevel.INFO, "Saved %s" % os.path.join(outputdir, composite.getTitle()))
    if show:
        composite.show()

# clean up
if GraphicsEnvironment.isHeadless():
    os.system("kill %d" % os.getpid())
