#install.packages("reticulate")
# ijob -A berglandlab -c1 -p largemem --mem=64G
#   module load gcc/9.2.0 openmpi/3.1.6 R/4.2.1

args = commandArgs(trailingOnly=TRUE)
file=as.character(args[1])

#file="me10247.animal9.0.0.0.0.0-NB_seg.npy"


# load reticulate and use it to load numpy
library(reticulate)
library(data.table)
library(foreach)

message("libraries loaded")

np <- import("numpy")

message("data loaded")
mat <- np$load(file, allow_pickle=T)
str(mat)

tmp <- mat[[1]]$masks
nMasks <- length(unique(unlist(sapply(asplit(tmp, 1), function(x) unique(expand.grid(x)$Var1)))))

message("num masks")
nMasks

 #  zmask <- foreach(i=1:89)%do%{
 #    xy <- expand.grid(tmp[i,,])
 #    xy[,x:=rep(1:dim(tmp[i,,])[1])]
 #    data.table(z=i, uniq=unique()$Var1), midX=)
 #
 #  }
 #  zmask <- rbindlist(zmask)
 #  zmask[,list(nZ=length(unique(z))), list(uniq)]

message("writing output")
write.table(data.table(file=file, nMasks=nMasks, quote=F, row.names=F, sep=",", col.names=F,
          file=paste(file, ".nMasks", sep=""))
