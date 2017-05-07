##### accept command line arguments ####

args <- commandArgs(trailingOnly = TRUE)

require('R.matlab')

# print(args)

subj.mat <- readMat(args)

subj.mat <- readMat('/mnt/c/Users/john/Desktop/practice_PLS/output/GO/Older/noCustomReg_GO_sart_old_erCVA_JE_erCVA/intermediate_processed/split_info/4356_run1.mat')

##### extract data #####

subj.mat <- subj.mat$split.info

subj.mat[4][[1]][2]
