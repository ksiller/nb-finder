#install.packages("reticulate")

args = commandArgs(trailingOnly=TRUE)
file=as.character(args[1])

#file="me10247.animal10.0.0.0.0.0-NB_seg.npy"


# load reticulate and use it to load numpy
library(reticulate)
library(data.table)

np <- import("numpy")
mat <- np$load(file, allow_pickle=T)
write.table(data.table(file=file, nMasks=dim(mat[[1]]$masks)[1]), quote=F, row.names=F, sep=",", col.names=F,
          file=paste(file, ".nMasks", sep=""))
