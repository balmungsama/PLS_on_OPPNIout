##### load libraries #####
library(plyr)
library(ggplot2)

mvOutliers <- '/home/hpc3586/JE_packages/mvOutliers'

for (source_file in list.files(mvOutliers, full.names = T) ) {
  source(source_file)
}

##### prepare for input #####
args        <- commandArgs(trailingOnly = TRUE)
unused_args <- NULL

##### default values #####

PREFIX <- ''
RM_OUT <- TRUE

mum_perm   <- 500
num_split  <- 100
num_boot   <- 1000
boot_type  <- 'strat'
clim       <- 95
save_data  <- 1

##### input arguments #####

for (arg in args) {
  arg <- strsplit(arg, split = '=')[[1]]
  if (arg[1] == '--PATH') {
    
    PATH <- arg[2]
    
    if (dir.exists(PATH) == F) { stop('"', PATH, '"', ' is not a valid directory.') }
    
  } else if (arg[1] == '--BEHAV_DIR') {
    
    BEHAV_DIR <- arg[2]
    
    if ( dir.exists(BEHAV_DIR) == F ) { stop('"', BEHAV_DIR, '"', ' is not a valid directory.') }
    
  } else if (arg[1] == '--VARBS') {
    
    VARBS <- arg[2]
    VARBS <- strsplit(VARBS, split = ' ')[[1]]
    
  } else if (arg[1] == '--GROUPS') {
    
    GROUPS <- arg[2]
    GROUPS <- strsplit(GROUPS, split = ' ')[[1]]
    
  } else if (arg[1] == '--PREFIX') {
    
    PREFIX <- arg[2]
    
  } else if (arg[1] == '--RM_OUT') {
    
    RM_OUT <- arg[2] 
    
  }  else if (arg[1] == '--CONDS') {
    
    CONDS <- arg[2] 
    CONDS <- strsplit(CONDS, split = ' ')[[1]]
    
  } else if (arg[1] == '--PLS_opt') {
    
    PLS_opt <- arg[2] 
    
    if (!PLS_opt %in% 1:6) { stop(PLS_opt, ' is not a valid PLS Option Enter a number from 1 to 6.') }
    
  } else if (arg[1] == '--MEAN_type') {
    
    MEAN_type <- arg[2] 
    
    if (!MEAN_type %in% 0:3) { stop(MEAN_type, ' is not a valid Mean-Centering type. Enter a number from 0 to 3.') }
    
  } else if (arg[1] == '--COR_mode') {
    
    COR_mode <- arg[2] 
    
    if (!COR_mode %in% c(0, 2, 4, 6)) { stop(COR_mode, ' is not a valid Correlation Mode. Enter either 0, 2, 4, or 6.') }
    
  } else if (arg[1] == '--num_perm') {
    
    num_perm <- arg[2] 
    
  } else if (arg[1] == '--num_split') {
    
    num_split <- arg[2] 
    
  } else if (arg[1] == '--num_boot') {
    
    num_boot <- arg[2] 
    
  } else if (arg[1] == '--boot_type') {
    
    boot_type <- arg[2] 
    
  } else if (arg[1] == '--clim') {
    
    clim <- arg[2] 
    
    if (!clim %in% 1:99) { stop('Enter a confidence interval between 1 and 99') }
    
  } else if (arg[1] == '--save_data') {
    
    save_data <- arg[2] 
    
    if (save_data != 1) { warning('Results will not be saved to a stacked datamat.') }
    
  } else if (arg[1] == '--CONTRASTS') {
    
    CONTRASTS <- arg[2] 
    
    CONTRASTS.list   <- NULL
    CONTRASTS.length <- NULL
    
    # CONTRASTS <- '1 -1 1 -1; 1 1 -1 -1, 1 -1 -1 1: 1 0 -1 0' # comment out
    
    CONTRASTS <- strsplit(CONTRASTS, split = "\\,|\\;|\\:")[[1]]
    
    for (contrast in 1:length(CONTRASTS)) {
      count <- contrast
      
      contrast                <- CONTRASTS[count]      
      contrast                <- trimws( contrast )
      CONTRASTS.list[[count]] <- strsplit( contrast , split = ' ')[[1]]
      CONTRASTS.list[[count]] <- as.numeric( CONTRASTS.list[[count]] )
      
      CONTRASTS.length        <- c(CONTRASTS.length, length(CONTRASTS.list[[count]]))
    }
    
    CONTRASTS <- do.call(what = 'rbind', args =  CONTRASTS.list)
    
    if (sum(CONTRASTS) != 0) { 
      CONTRASTS <- NULL
      stop('All contrasts must sum to zero.') 
    } else if ( length(unique(CONTRASTS.length)) > 1) {
      CONTRASTS <- NULL
      stop('All contrasts must have the same number of digits') 
    }
    
    
  } else {
    
    unused_args <- c(unused_args, paste0(arg[1], '=', arg[2]))
    
  }
}

##### sanity checks #####

if (dim(CONTRASTS)[2] != length(GROUPS) * length(CONDS)) { 
  stop('The length of each contrast must be equal to the number of groups times the number conditions') 
}

##### set wd #####

setwd(PATH)

##### create placeholder variables #####
subj.files <- NULL
subj.IDs   <- NULL
behav.list <- NULL
behav.grp  <- NULL
outliers   <- NULL

##### collect group .mat files #####
for (group in GROUPS) {
  subj.files[[group]] <- Sys.glob(paste0(group, '_', PREFIX, '*fMRIsessiondata.mat') )
  
  grp.ids <- NULL
  for (subj in subj.files[[group]]) {

    subj <- strsplit(x = subj, split = '_')
    subj <- subj[[1]]
    subj <- subj[length(subj) - 1]
    
    grp.ids <- c(grp.ids, subj)
  }
  
  subj.IDs[[group]] <- grp.ids
}

##### get behavioural data #####

for (group in GROUPS) {
  
  for (varb in VARBS) {
    
    tmp.varb <- read.table(file = file.path(BEHAV_DIR, group, paste0(varb, '.txt')), header = T)
    tmp.varb <- tmp.varb[order(tmp.varb$subject_id), ]
    
    behav.list[[varb]] <- tmp.varb
  }
  
  # behav.grp[[group]] <- ldply(behav.list, cbind)
  behav.grp[[group]] <- do.call(what = 'cbind', args =  behav.list)
  
  ##### flagging outliers #####
  
  if (length(VARBS) > 1) {
    
    outliers[[group]] <- multiOut(dat = cbind(timept = 1,
                                              behav.grp[[group]]), 
                                  exVar = NULL, 
                                  rmdo_alpha = 0.5)
    
    outliers[[group]]$flagged  <- as.character( unique(outliers[[group]]$outliers$subject_id) )
    behav.grp[[group]]$outlier <- behav.grp[[group]]$subject_id %in% outliers[[group]]$flagged
    
  } else {
    tmp.varb <- behav.grp[[group]][, - which(colnames(behav.grp[[group]]) == 'subject_id')]
    outliers[[group]]$flagged <- which( abs(tmp.varb[,1] - mean(tmp.varb[,1])) > 3*sd(x = tmp.varb[,1]) )
    outliers[[group]]$flagged <- behav.grp[[group]] [outliers[[group]]$flagged, 'subject_id']
    
    behav.grp[[group]]$outlier <-  behav.grp[[group]]$subject_id %in% outliers[[group]]$flagged
  }
  
  
  ##### add group row labels #####
  
  behav.grp[[group]] <- cbind(group = group, behav.grp[[group]])
  
}

behav.tab <- do.call(what = 'rbind', args = behav.grp)
row.names(behav.tab) <- NULL

##### WRITE: Defining Output Filename #####

# defining the output file name
output.file <- paste0(paste(GROUPS, collapse = '&'), '_', paste(VARBS, collapse = '&'), '_analysis.txt')
output.file <- file.path(PATH, output.file)

# line seperator

line.sep <- '\n%------------------------------------------------------------------------\n'

##### WRITE: Group Selection Start #####

write(x = line.sep, file = output.file, append = FALSE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Group Section Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

for (group in GROUPS) {
  write(x = paste( c('group_files', subj.files[[group]]) , collapse = ' '), file = output.file, append = TRUE)
}

write(x = '\n% ... following above pattern for more groups\n', file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%', file = output.file, append = TRUE)
write(x = '	%  Group Section End  %', file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%', file = output.file, append = TRUE)

##### WRITE: PLS Section Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  PLS Section Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = '%  Notes:'                                                                  , file = output.file, append = TRUE)
write(x = '%    1. Mean-Centering PLS'                                                 , file = output.file, append = TRUE)
write(x = '%    2. Non-Rotated Task PLS (please also fill out contrast data below)'    , file = output.file, append = TRUE)
write(x = '%    3. Regular Behav PLS (please also fill out behavior data & name below)', file = output.file, append = TRUE)
write(x = '%    4. Multiblock PLS (please also fill out behavior data & name below)'   , file = output.file, append = TRUE)
write(x = '%    5. Non-Rotated Behav PLS (please also fill out contrast data and'      , file = output.file, append = TRUE)
write(x = '%	behavior data & name below)'                                             , file = output.file, append = TRUE) 
write(x = '%    6. Non-Rotated Multiblock PLS (please also fill out contrast data and' , file = output.file, append = TRUE)
write(x = '%	behavior data & name below)\n'                                           , file = output.file, append = TRUE)

write(x = paste0('pls    ', PLS_opt, '    % PLS Option (between 1 to 5, see above notes)\n'), file = output.file, append = TRUE)

write(x = '%  Mean-Centering Type:'                                                    , file = output.file, append = TRUE)
write(x = '%    0. Remove group condition means from conditon means within each group' , file = output.file, append = TRUE)
write(x = '%    1. Remove grand condition means from each group condition mean'        , file = output.file, append = TRUE)
write(x = '%    2. Remove grand mean over all subjects and conditions'                 , file = output.file, append = TRUE)
write(x = '%    3. Remove all main effects by subtracting condition and group means\n' , file = output.file, append = TRUE)

write(x = paste0('mean_type    ', MEAN_type, '    % Mean-Centering Type (between 0 to 3, see above)\n'), file = output.file, append = TRUE)

write(x = '%  Correlation Mode:'       , file = output.file, append = TRUE)
write(x = '%    0. Pearson correlation', file = output.file, append = TRUE)
write(x = '%    2. covaraince'         , file = output.file, append = TRUE)
write(x = '%    4. cosine angle'       , file = output.file, append = TRUE)
write(x = '%    6. dot product\n'      , file = output.file, append = TRUE)

write(x = paste0('cormode    ', COR_mode, '    % Correlation Mode (can be 0,2,4,6, see above)\n'), file = output.file, append = TRUE)

write(x = paste0('num_perm	' , num_perm,   '		% Number of Permutation'                   ), file = output.file, append = TRUE)
write(x = paste0('num_split	' , snum_split, '		% Natasha Perm Split Half'                 ), file = output.file, append = TRUE)
write(x = paste0('num_boot	' , num_boot,   '		% Number of Bootstrap'                     ), file = output.file, append = TRUE)
write(x = paste0('boot_type	' , boot_type,  '		% Either strat or nonstrat bootstrap type' ), file = output.file, append = TRUE)
write(x = paste0('clim		'   , clim,       '		% Confidence Level for Behavior PLS'       ), file = output.file, append = TRUE)
write(x = paste0('save_data	' , save_data,  '		% Set to 1 to save stacked datamat\n'      ), file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  PLS Section End  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

##### WRITE: Condition Selection Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Condition Selection Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = paste0('%  Notes: If you don', "'t need to deselect conditions, just leave"), file = output.file, append = TRUE)
write(x = '%  "selected_cond" & "selected_bcond" to be commented.\n', file = output.file, append = TRUE)

write(x = '%  First put k number of 1 after "selected_cond" keyword, where k is the' , file = output.file, append = TRUE)
write(x = '%  number of conditions in the session/datamat. Then, replace with 0 for' , file = output.file, append = TRUE)
write(x = '%  those conditions that you would like to deselect for any case except'  , file = output.file, append = TRUE)
write(x = '%  behavior block of multiblock PLS. e.g. If you have 3 conditions in '   , file = output.file, append = TRUE)
write(x = '%  session/datamat, and you would like to deselect the 2nd condition, '   , file = output.file, append = TRUE)
write(x = '%  then you should enter 1 0 1 after selected_cond.'                      , file = output.file, append = TRUE)
write(x = '%'                                                                        , file = output.file, append = TRUE)
write(x = '%selected_cond	1 1		% you may want to comment this line\n'               , file = output.file, append = TRUE)

write(x = '%  First put k number of 1 after "selected_bcond" keyword, where k is the', file = output.file, append = TRUE)
write(x = '%  number of conditions in sessiondata file. Then, replace with 0 for'    , file = output.file, append = TRUE)
write(x = '%  those conditions that you would like to deselect only for behavior '   , file = output.file, append = TRUE)
write(x = '%  block of multiblock PLS. e.g. If you have 3 conditions in '            , file = output.file, append = TRUE)
write(x = '%  sessiondata file, and you would like to deselect the 2nd condition, '  , file = output.file, append = TRUE)
write(x = '%  then you should enter 1 0 1 after selected_cond. you can not select '  , file = output.file, append = TRUE)
write(x = '%  any conditions for "selected_bcond" that were deselected in '          , file = output.file, append = TRUE)
write(x = '%  "selected_cond". e.g. in the above comments, you can not select the '  , file = output.file, append = TRUE)
write(x = '%  2nd condition for "selected_bcond" because it was already deselected ' , file = output.file, append = TRUE)
write(x = '%  in "selected_cond".'                                                   , file = output.file, append = TRUE)
write(x = '%'                                                                        , file = output.file, append = TRUE)
write(x = '%selected_bcond	1 1		% you may want to comment this line\n'             , file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Condition Selection End  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

##### WRITE: Contrast Data Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Contrast Data Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = '%  Notes: only list selected conditions (selected_cond)\n', file = output.file, append = TRUE)

for (contrast in 1:dim(CONTRASTS)[1]) {
  contrast <- CONTRASTS[contrast, ]
  write(x = contrast, file = output.file, append = TRUE)
}

write(x = '\n% ... following above pattern for more groups\n', file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Contrast Data End  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

##### WRITE: Behavior Data Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Behavior Data Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = '%  Notes: only list selected conditions (selected_cond)\n', file = output.file, append = TRUE)

for (group in GROUPS) {
  for (subject in 1:dim(behav.grp[[group]] )[1] ) {
    behav.tmp <- behav.grp[[group]]
    behav.tmp <- behav.tmp[subject, VARBS]
    behav.tmp <- as.numeric(behav.tmp)
    behav.tmp <- paste(c('behavior_data', behav.tmp) , collapse = ' ')
    
    write(x = behav.tmp, file = output.file, append = TRUE)
    
  }
  write(x = ' ', file = output.file, append = TRUE)
}

write(x = '\n% ... following above pattern for more groups\n', file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)
write(x = '	%  Behavior Data End  %' , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)

##### WRITE: Behavior Name Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)
write(x = '	%  Behavior Name Start  %' , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)

write(x = '\n%  Numbers of Behavior Name should match the Behavior Data above\n', file = output.file, append = TRUE)

write(x = paste( c('behaviour_name', VARBS), collapse = ' ' ) , file = output.file, append = TRUE)

write(x = '\n	%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)
write(x =  '	%  Behavior Name End  %' , file = output.file, append = TRUE)
write(x =  '	%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)

write(x = line.sep, file = output.file, append = TRUE)
