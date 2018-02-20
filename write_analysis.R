##### load libraries #####
library('plyr')
library('R.matlab')

# mvOutliers <- '/home/hpc3586/JE_packages/mvOutliers'

# for (source_file in list.files(mvOutliers, full.names = T) ) {
#   source(source_file)
# }

##### prepare for input #####
args        <- commandArgs(trailingOnly = TRUE)
unused_args <- NULL

##### default values #####

PREFIX <- ''
RM_OUT <- FALSE

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
		
	} else if (arg[1] == '--BEHAV_DIR') {
		
		BEHAV_DIR <- arg[2]
				
	} else if (arg[1] == '--VARBS') {
		
		VARBS <- arg[2]
		VARBS <- strsplit(VARBS, split = "\\,|\\;|\\:")[[1]]
		
	} else if (arg[1] == '--GROUPS') {
		
		GROUPS <- arg[2]
		GROUPS <- strsplit(GROUPS, split = "\\,|\\;|\\:")[[1]]
		
	} else if (arg[1] == '--PREFIX') {
		
		PREFIX <- arg[2]
		
	} else if (arg[1] == '--RM_OUT') {
		
		RM_OUT <- arg[2] 
		
	}  else if (arg[1] == '--CONDS') {
		
		CONDS <- arg[2] 
		CONDS <- strsplit(CONDS, split = "\\,|\\;|\\:")[[1]]
		
	} else if (arg[1] == '--PLS_opt') {
		
		PLS_opt <- arg[2] 
		
		
	} else if (arg[1] == '--MEAN_type') {
		
		MEAN_type <- arg[2] 
		
		
	} else if (arg[1] == '--COR_mode') {
		
		COR_mode <- arg[2] 
		
		
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
		
		
	} else if (arg[1] == '--save_data') {
		
		save_data <- arg[2] 
		
		
	} else if (arg[1] == '--CONTRASTS') {
		
		CONTRASTS <- arg[2] 
	
		if (CONTRASTS != 'NULL') { 

			CONTRASTS <- strsplit(CONTRASTS, split = "\\,|\\;|\\:")[[1]]
		
			CONTRASTS.list   <- NULL
			CONTRASTS.length <- NULL
			
			# CONTRASTS <- '1 -1 1 -1; 1 1 -1 -1, 1 -1 -1 1: 1 0 -1 0' # comment out
			
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

			if (dim(CONTRASTS)[2] != length(GROUPS) * length(CONDS)) { 
				stop('The length of each contrast must be equal to the number of groups times the number conditions') 
			}
		}

		
		
	} else if (arg[1] == '--REMOVE_LS') {

		REMOVE_LS <- strsplit(arg[2], split = "\\,|\\;|\\:|\\ ")[[1]]

	} else {
		
		unused_args <- c(unused_args, paste0(arg[1], '=', arg[2]))
		
	}
}

##### sanity checks #####

if (dir.exists(PATH) == F) { stop('"', PATH, '"', ' is not a valid directory.') }
if ( dir.exists(BEHAV_DIR) == F ) { stop('"', BEHAV_DIR, '"', ' is not a valid directory.') }
if (!PLS_opt %in% 1:6) { stop(PLS_opt, ' is not a valid PLS Option Enter a number from 1 to 6.') }
if (!MEAN_type %in% 0:3) { stop(MEAN_type, ' is not a valid Mean-Centering type. Enter a number from 0 to 3.') }
if (!COR_mode %in% c(0, 2, 4, 6)) { stop(COR_mode, ' is not a valid Correlation Mode. Enter either 0, 2, 4, or 6.') }
if (!clim %in% 1:99) { stop('Enter a confidence interval between 1 and 99') }
if (save_data != 1) { warning('Results will not be saved to a stacked datamat.') }

##### set wd #####

setwd(PATH)

##### create placeholder variables #####
subj.files <- list()
subj.IDs   <- NULL
behav.list <- NULL
behav.grp  <- NULL
outliers   <- NULL

##### make sure variable names are properly formatted when importing from Matlab #####
VARBS <- gsub("_", ".", VARBS)

##### collect group .mat files #####
for (group in GROUPS) {
	subj.files[[group]] <- Sys.glob(paste0(PREFIX, '_', group, '_', '*fMRIsessiondata.mat') )

	# remove any specified subjects
	print(paste('REMOVE_LS exists:',exists('REMOVE_LS')))

	if (exists('REMOVE_LS')) {
		REMOVE_LS.tmp <- unique( grep(paste(REMOVE_LS,collapse="|"),subj.files[[group]], value=F) )

		if (length(REMOVE_LS.tmp) > 0) {
			subj.files[[group]] <- subj.files[[group]][-REMOVE_LS.tmp] #[[group]]
			print(subj.files[[group]])
		}
	}
	
	grp.ids <- NULL
	for (subj in subj.files[[group]]) {

		subj <- strsplit(x = subj, split = paste0(PREFIX, '_', group, '_'))
		subj <- subj[[1]][2]
		subj <- strsplit(x = subj, split = '_')
		subj <- subj[[1]][1]
		
		grp.ids <- c(grp.ids, subj)
	}
	
	subj.IDs[[group]] <- grp.ids
}

##### get behavioural data #####
behav.values <- list()
for (group in GROUPS) {

	for (subj in subj.IDs[[group]]) {
		tmp.varb <- readMat(file.path(BEHAV_DIR, paste0(subj, '.mat')))
		tmp.varb <- tmp.varb[[1]][,,1]

		for (run in tmp.varb$Runs) {
			tmp.behav.row <- NULL
			for (varb in VARBS) {
				tmp.behav.meas <- tmp.varb[[varb]][run]
				tmp.behav.row <- c(tmp.behav.row, tmp.behav.meas)
			}
			tmp.behav.row <- data.frame(t(tmp.behav.row))
			colnames(tmp.behav.row) <- VARBS
			tmp.behav.row <- cbind(tmp.behav.row, group, subj, run)
			if (length(behav.values) < which(GROUPS == group)) {
				 behav.values[[group]] <- tmp.behav.row
			} else {
				behav.values[[group]] <- rbind(behav.values[[group]], tmp.behav.row)
			}
		}
	}

	behav.values[[group]] <- behav.values[[group]][order(behav.values[[group]]$run),]
	
	##### flagging outliers #####
	if (RM_OUT == T) {
		
		if (length(VARBS) > 1) {
			
			outliers[[group]] <- multiOut(dat = cbind(timept = 1,
																								behav.grp[[group]]), 
																		exVar = NULL, 
																		rmdo_alpha = 0.5)
			
			outliers[[group]]$flagged  <- as.character( unique(outliers[[group]]$outliers$subject_id) )
			behav.grp[[group]]$outlier <- behav.grp[[group]]$subject_id %in% outliers[[group]]$flagged
			
		} else {
			
			tmp.varb <- data.frame(behav.grp[[group]][ , -which(colnames(behav.grp[[group]]) == 'subject_id') ])
			colnames(tmp.varb) <- colnames(behav.grp[[group]])[ -which(colnames(behav.grp[[group]]) == 'subject_id') ]
			
			outliers[[group]]$flagged <- which( abs(tmp.varb[,1] - mean(tmp.varb[,1])) > 3*sd(x = tmp.varb[,1]) )
			outliers[[group]]$flagged <- behav.grp[[group]] [outliers[[group]]$flagged, 'subject_id']
			
			behav.grp[[group]]$outlier <-  behav.grp[[group]]$subject_id %in% outliers[[group]]$flagged
			
		}
		
	}
	
}

behav.tab <- ldply(behav.values, data.frame)
behav.tab <- behav.tab[,VARBS]
behav.tab <- data.frame(labels = 'behavior_data', behav.tab, collapse = ' ')

##### WRITE: Defining Output Filename #####

# defining the output file name
output.file <- paste0(paste(GROUPS, collapse = '&'), '_', paste(VARBS, collapse = '&'), '_analysis.txt')
output.file <- file.path(PATH, output.file)

# defining the results file
results.file <- paste0(paste(GROUPS, collapse = '&'), '_', paste(VARBS, collapse = '&'), '_fMRIresult.mat')

# line seperator

line.sep <- '\n%------------------------------------------------------------------------\n'

##### WRITE: Group Selection Start #####

write(x = line.sep, file = output.file, append = FALSE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Result File Name Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = paste0('result_file ', results.file), file = output.file, append = TRUE)

write(x = '\n	%%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x =  '	%  Result File Name End  %'    , file = output.file, append = TRUE)
write(x =  '	%%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Group Section Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

for (group in GROUPS) {
	write(x = paste( c('group_files', subj.files[[group]]) , collapse = ' '), file = output.file, append = TRUE)
}

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%', file = output.file, append = TRUE)
write(x = '	%  Group Section End  %', file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%', file = output.file, append = TRUE)

##### WRITE: PLS Section Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  PLS Section Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = paste0('pls    ', PLS_opt, '    % PLS Option (between 1 to 5, see above notes)\n'), file = output.file, append = TRUE)

write(x = paste0('mean_type    ', MEAN_type, '    % Mean-Centering Type (between 0 to 3, see above)\n'), file = output.file, append = TRUE)

write(x = paste0('cormode    ', COR_mode, '    % Correlation Mode (can be 0,2,4,6, see above)\n'), file = output.file, append = TRUE)

write(x = paste0('num_perm	' , num_perm,   '		% Number of Permutation'                   ), file = output.file, append = TRUE)
write(x = paste0('num_split	' , num_split, '		% Natasha Perm Split Half'                 ), file = output.file, append = TRUE)
write(x = paste0('num_boot	' , num_boot,   '		% Number of Bootstrap'                     ), file = output.file, append = TRUE)
write(x = paste0('boot_type	' , boot_type,  '		% Either strat or nonstrat bootstrap type' ), file = output.file, append = TRUE)
write(x = paste0('clim		'   , clim,       '		% Confidence Level for Behavior PLS'       ), file = output.file, append = TRUE)
write(x = paste0('save_data	' , save_data,  '		% Set to 1 to save stacked datamat\n'      ), file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%'      , file = output.file, append = TRUE)
write(x = '	%  PLS Section End  %'      , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%\n'    , file = output.file, append = TRUE)

##### WRITE: Condition Selection Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Condition Selection Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = '\n	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'    , file = output.file, append = TRUE)
write(x =  '	%  Condition Selection End  %'    , file = output.file, append = TRUE)
write(x =  '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n'  , file = output.file, append = TRUE)

##### WRITE: Contrast Data Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Contrast Data Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

if (CONTRASTS != 'NULL') {
	for (contrast in 1:dim(CONTRASTS)[1]) {
		contrast <- CONTRASTS[contrast, ]
		write(x = paste0( c('contrast_data ', contrast), collapse = ' '), file = output.file, append = TRUE)
	}
}

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%'    , file = output.file, append = TRUE)
write(x = '	%  Contrast Data End  %'    , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%\n'  , file = output.file, append = TRUE)

##### WRITE: Behavior Data Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Behavior Data Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

for (line in 1:dim(behav.tab)[1]) {
	write(x = paste(behav.tab[line, ], collapse = ' '), file = output.file, append = TRUE)
}

write(x = ' ', file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%'    , file = output.file, append = TRUE)
write(x = '	%  Behavior Data End  %'    , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%'    , file = output.file, append = TRUE)

##### WRITE: Behavior Name Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)
write(x = '	%  Behavior Name Start  %' , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%\n' , file = output.file, append = TRUE)

write(x = paste( c('behavior_name', VARBS), collapse = ' ' ) , file = output.file, append = TRUE)

write(x = '\n	%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)
write(x =  '	%  Behavior Name End  %' , file = output.file, append = TRUE)
write(x =  '	%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)

write(x = line.sep, file = output.file, append = TRUE)
