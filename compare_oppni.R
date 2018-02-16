
#### user-set parameters #####

TOP_DIR <- 'C:/Users/john/Desktop/pls_results/QC/Younger'

##### load libraries #####

library('ggplot2')
library('R.matlab')
source('C:/Users/john/OneDrive/2015/McIntosh_Lab/Project Development/Proposal/Given data/RAW SART/scripts/mvOutliers/outlierFunctions_v2.R'         )
source('C:/Users/john/OneDrive/2015/McIntosh_Lab/Project Development/Proposal/Given data/RAW SART/scripts/mvOutliers/MahalanobisOutlierFunctions.R' )

##### loading data #####

setwd(TOP_DIR)

group_pca  <- readMat( file.path('QC2_results', 'group_pca.mat' ) )
output_qc1 <- readMat( file.path('QC1_results', 'output_qc1.mat') )
output_qc2 <- readMat( file.path('QC2_results', 'output_qc2.mat') )

output_qc1 <- output_qc1$output.qc1
output_qc2 <- output_qc2$output_qc2
group_pca  <- group_pca$group.pca

##### detect outliers - PCA #####

outlier <- list()

for (pipe in 1:length(group_pca)) {
  
  pca_scores            <- group_pca[[pipe]][3][[1]]
  pca_scores            <- as.data.frame(pca_scores)
  pca_scores$timept     <- 1
  pca_scores$subject_id <- 1:dim(pca_scores)[1]
  
  tmp.Outliers <- multiOut(dat = pca_scores, rmdo_alpha = 0.9, exVar = c(), alpha = 0.05)
  
  outlier[[pipe]]         <- paste0('------------ Pipeline ', labels(group_pca)[[1]][pipe], ' ------------')
  outlier[[pipe]]$var     <- data.frame(var = group_pca[[pipe]][4][[1]])
  outlier[[pipe]]$output  <- tmp.Outliers
    
  if (pipe < length(group_pca)) {
    readline(prompt = "Press [enter] to continue")
  }
  
}

# tmp.outTab <- exgData[which(exgData$group== group), c('subj', 'mu', 'sigma', 'tau', 'logErr')]
# tmp.outTab$timept <- 1
# names(tmp.outTab)[which(names(tmp.outTab) == 'subj')] <- 'subject_id'
# 
# tmp.Outliers <- multiOut(dat = tmp.outTab, rmdo_alpha = 0.9, exVar = c(), alpha = 0.05)
# mvOuts <- c(mvOuts, as.numeric(as.character(tmp.Outliers$outliers$subject_id)))
# 
# print(paste('Outliers:', paste(as.character(tmp.Outliers$outliers$subject_id), collapse = ' ')))
# 
# exgData <- exgData[-which(exgData$subj %in% mvOuts), ]
# row.names(exgData) <- NULL