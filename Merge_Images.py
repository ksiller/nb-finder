#@ File (label="fluorescent image") imgfile
#@ File (label="mask") maskfile
#@ File (label="output image file") outputfile

from ij.plugin import RGBStackMerge
from ij import IJ

red = IJ.openImage(imgfile.getAbsolutePath())
green = IJ.openImage(maskfile.getAbsolutePath())
blue = green
keepSources = True
composite = RGBStackMerge.mergeChannels([red, green, blue], keepSources)
# composite.show()
IJ.saveAs(composite, "TIFF", outputfile.getAbsolutePath())
