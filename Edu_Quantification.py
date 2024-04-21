#@ File (label="NB segmentation image") nbfile
#@ File (label="EDU image") edufile
#@ File (label="Output directory", style="directory", required=False) outputdir
#@ Boolean (label="Watershed neuorblasts", value=False) watershed
#@ LogService logger

from java.awt import GraphicsEnvironment
import jarray.zeros
import os

from ij import IJ, ImagePlus, WindowManager
from ij.measure import ResultsTable
from ij.plugin import ImageCalculator, RGBStackMerge
from org.scijava.log import LogLevel
from loci.plugins import BF
from loci.plugins.in import ImporterOptions

def open_hyperstack(fname):
    logger.log(LogLevel.INFO, "Opening %s" % fname)
    opts = ImporterOptions()
    opts.setId(fname)
    #opts.setSplitChannels(True)
    colorImps = BF.openImagePlus(opts)
    return colorImps


def segment(nb_imp, low_threshold=32, min_size=0, watershed=False):
    IJ.run(nb_imp, "3D Simple Segmentation", "seeds=None low_threshold=%d min_size=%d max_size=-1" % (low_threshold, min_size))
    if watershed:
        IJ.run("3D Watershed Split", "binary=Bin seeds=Automatic radius=2")
        nbbin = WindowManager.getImage("Split")
    else:
        nbbin = WindowManager.getImage("Bin")
    nbseg = WindowManager.getImage("Seg")
    logger.log(LogLevel.INFO, "Segmentation done.")
    return nbbin, nbseg


def measure(objects_imp, measure_imp):
    rt = ResultsTable.getResultsTable()
    rt.reset()
    image = ".".join(measure_imp.getTitle().split(".")[:-1])
    logger.log(LogLevel.INFO, "Analyzing %s" % image)

    IJ.run("3D Intensity Measure", "objects=%s signal=%s" % (objects_imp.getTitle(), image))
    return rt


def merge(nb_imp, edu_imp, ctype="8-bit"):
    channels = jarray.zeros(3, ImagePlus)
    IJ.run(nb_imp, ctype, "")
    IJ.run(edu_imp, ctype, "")
    channels[0] = nb_imp
    channels[1] = ImageCalculator.run(nb_imp, edu_imp, "and create stack")
    channels[2] = ImageCalculator.run(edu_imp, channels[1], "subtract create stack")
    composite = RGBStackMerge.mergeChannels(channels, True)
    logger.log(LogLevel.INFO, "Completed merging")
    return composite

def save_image(imp, fname, outputdir, suffix=""):
    if "." in fname:
        fname = ".".join(fname.split(".")[:-1])
    fname = fname + suffix + ".tif" 
    abspath = os.path.join(outputdir, fname)
    IJ.saveAsTiff(imp, abspath)
    logger.log(LogLevel.INFO, "Saved %s" % abspath)


if outputdir is None:
    outputdir = nbfile.getParent()
else:
    outputdir = outputdir.getAbsolutePath()

# load images
nb_imp = open_hyperstack(str(nbfile))[0]
edu_imp = open_hyperstack(str(edufile))[0]

# need to show images for further processing
nb_imp.show()
edu_imp.show()

# segment
nb_bin_imp, nb_seg_imp = segment(nb_imp)

# measure
rt = measure(nb_bin_imp, edu_imp)
rt.save(os.path.join(outputdir, ".".join(nb_imp.getTitle().split(".")[:-1])+"-results.csv"))

# create composite image
composite = merge(nb_imp, edu_imp)
composite.show()

# save images
save_image(nb_bin_imp, nb_imp.getTitle(), outputdir, suffix="-binary")
save_image(nb_seg_imp, nb_imp.getTitle(), outputdir, suffix="-segmented")
save_image(composite, nb_imp.getTitle(), outputdir, suffix="-withEdu")

# clean up
if GraphicsEnvironment.isHeadless():
    os.system("kill %d" % os.getpid())


