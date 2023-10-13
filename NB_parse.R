#install.packages("reticulate")
# ijob -A berglandlab -c1 -p largemem --mem=64G
#   module load gcc/9.2.0 openmpi/3.1.6 R/4.2.1

args = commandArgs(trailingOnly=TRUE)
file=as.character(args[1])

#file="me10247.animal10.0.0.0.0.0-NB_seg.npy"


# load reticulate and use it to load numpy
library(reticulate)
library(data.table)

np <- import("numpy")
mat <- np$load(file, allow_pickle=T)

tmp <- mat[[1]]$masks
nMasks <- length(unique(unlist(sapply(asplit(tmp, 1), function(x) unique(expand.grid(x)$Var1)))))
nMasks

write.table(data.table(file=file, nMasks=nMasks, quote=F, row.names=F, sep=",", col.names=F,
          file=paste(file, ".nMasks", sep=""))
