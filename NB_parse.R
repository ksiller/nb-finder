#install.packages("reticulate")

args = commandArgs(trailingOnly=TRUE)
file=as.character(args[1])



# load reticulate and use it to load numpy
library(reticulate)
library(data.table)

np <- import("numpy")
mat <- np$load(file, allow_pickle=T)
write.csv(data.table(file=file, nMasks=dim(mat[[1]]$masks)[1]), quote=F, row.names=F,
          file=paste(file, ".nMasks", sep=""))
