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

mum_perm   <- 500
num_split  <- 100
num_boot   <- 1000
boot_type  <- 'strat'
clim       <- 95
save_data  <- 1
GROUPS     <- NULL

##### input arguments #####

for (arg in args) {
  arg <- strsplit(arg, split = '=')[[1]]
  if (arg[1] == '--PATH') {

    PATH <- arg[2]

  } else if (arg[1] == '--VARBS') {

    VARBS <- arg[2]
    VARBS <- strsplit(VARBS, split = "\\,|\\;|\\:")[[1]]

  } else if (arg[1] == '--GROUPS') {

    GROUPS <- arg[2]
    GROUPS <- 'yng,old'
    GROUPS <- strsplit(GROUPS, split = "\\,|\\;|\\:")[[1]]
    print(GROUPS)

  } else if (arg[1] == '--PREFIX') {

    PREFIX <- arg[2]

  } else if (arg[1] == '--BEHAV_FILE') {

    BEHAV_FILE <- arg[2]

  }  else if (arg[1] == '--PLS_opt') {

    PLS_opt <- arg[2]
    PLS_opt <- as.numeric(PLS_opt)

  } else if (arg[1] == '--MEAN_type') {

    MEAN_type <- arg[2]
    MEAN_type <- as.numeric(MEAN_type)

  } else if (arg[1] == '--COR_mode') {

    COR_mode <- arg[2]
    COR_mode <- as.numeric(COR_mode)

  } else if (arg[1] == '--num_perm') {

    num_perm <- arg[2]
    num_perm <- as.numeric(num_perm)

  } else if (arg[1] == '--num_split') {

    num_split <- arg[2]
    num_split <- as.numeric(num_split)

  } else if (arg[1] == '--num_boot') {

    num_boot <- arg[2]
    num_boot <- as.numeric(num_boot)

  } else if (arg[1] == '--boot_type') {

    boot_type <- arg[2]

  } else if (arg[1] == '--CONDS') {

    CONDS <- arg[2]

  } else if (arg[1] == '--clim') {

    clim <- arg[2]
    clim <- as.numeric(clim)

  } else if (arg[1] == '--REMOVE_LS') {

    REMOVE_LS <- arg[2]

  } else if (arg[1] == '--save_data') {

    save_data <- arg[2]
    save_data <- as.logical(as.numeric(save_data))

  } else if (arg[1] == '--CONTRASTS') {

    CONTRASTS <- arg[2]

    if (!is.na(CONTRASTS)) {
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
      }
    }

  } else if (arg[1] == '--REMOVE_LS') {

    REMOVE_LS <- strsplit(arg[2], split = "\\,|\\;|\\:|\\ ")[[1]]

  } else if (arg[1] == '--indep_runs') {

    indep_runs <- arg[2]

  } else {

    unused_args <- c(unused_args, paste0(arg[1], '=', arg[2]))

  }
}

##### sanity checks #####
checkSanity <- function(PATH, BEHAV_FILE, PLS_opt, MEAN_type, COR_mode, clim, save_data, VARBS) {
  valid <- list(
    cor.mode  = c(0, 2, 4, 6),
    mean.type = c(0:3),
    clim      = 1:99
  )

  checkSanity.warningVaribles <- c('save_data')

  checkSanity.messages <- list(
    path.sessionData = paste0('"', PATH, '"', ' is not a valid directory.'),
    path.behav       = paste0('"', BEHAV_FILE, '"', ' is not a valid directory.'),
    pls.opt          = paste0(PLS_opt, ' is not a valid PLS option. Enter a number from 1 to 6.'),
    mean.type        = paste0(MEAN_type, ' is not a valid Mean-Centering type. Enter a number from 0 to 3.'),
    cor.mode         = paste0(COR_mode, ' is not a valid Correlation Mode. Enter either 0, 2, 4, or 6.'),
    clim             = paste0('Enter a confidence interval between 1 and 99'),
    save_data        = paste0('Results will not be saved to a stacked datamat.'),
    varbs            = paste0('Please specify which behavioural variables to use.')
    )

  checkSanity.checks <- NULL

  if ( dir.exists(PATH) == F                            ) {checkSanity.checks <- c(checkSanity.checks, "path.sessionData")}
  if ( file.exists(BEHAV_FILE) == F  && PLS_opt %in% 3:6) {checkSanity.checks <- c(checkSanity.checks, "path.behav")      }
  if ( !PLS_opt %in% 1:6                                ) {checkSanity.checks <- c(checkSanity.checks, "pls.opt")         }
  if ( !MEAN_type %in% 0:3                              ) {checkSanity.checks <- c(checkSanity.checks, "mean.type")       }
  if ( !COR_mode %in% c(0, 2, 4, 6)                     ) {checkSanity.checks <- c(checkSanity.checks, "cor.mode")        }
  if ( !clim %in% 1:99                                  ) {checkSanity.checks <- c(checkSanity.checks, "clim")            }
  if ( save_data != T                                   ) {checkSanity.checks <- c(checkSanity.checks, "save_data")       }
  if ( PLS_opt %in% 3:4 && is.na(VARBS)                 ) {checkSanity.checks <- c(checkSanity.checks, "varbs")           }

  if (length(checkSanity.checks) > 0) {
    for (check in checkSanity.checks) {
      checkSanity.output <- paste(check, sep = "\n")
    }

    if (mean(checkSanity.checks %in% checkSanity.warningVaribles)==1) {
      warning(checkSanity.output)
    } else {
      stop(checkSanity.output)
    }

  }
}

checkSanity(
  PATH      = PATH     ,
  BEHAV_FILE = BEHAV_FILE,
  PLS_opt   = PLS_opt  ,
  MEAN_type = MEAN_type,
  COR_mode  = COR_mode ,
  clim      = clim     ,
  save_data = save_data,
  VARBS     = VARBS
)

##### set wd #####
setwd(PATH)

##### make sure variable names are properly formatted when importing from Matlab #####
if (PLS_opt %in% 3:4) {
  VARBS <- gsub("_", ".", VARBS)
}

##### create placeholder variables #####
subj.files <- list()
subj.IDs   <- list()
subj.RUNS  <- list()
behav.grp  <- NULL
outliers   <- NULL

##### get behavioural data #####

get.behav <- function(BEHAV_FILE, GROUPS, ...) {
  behav.list <- list()
  behav.data <- read.csv(BEHAV_FILE, header = T, stringsAsFactors = F)

  # import data according to groups
  for (group in GROUPS) {
    behav.list[[group]] <- behav.data[which(behav.data$group == group),
                                      c('group', 'subj', 'run', VARBS)]
    behav.list[[group]] <- behav.list[[group]][order(behav.list[[group]]$subj), ]
    behav.list[[group]] <- behav.list[[group]][order(behav.list[[group]]$run ), ]
  }

  behav.table <- ldply(behav.list, data.frame)


  if (exists('REMOVE_LS') & sum(REMOVE_LS %in% behav.table$subj) > 0) {
    behav.table <- behav.table[-which(behav.table$subj %in% REMOVE_LS), ]
  }

  return(behav.table)
}

behav.table <- get.behav(BEHAV_FILE, GROUPS, REMOVE_LS)

##### collect group .mat files #####

get.sessionData <- function(PREFIX, GROUPS, behav.table) {
  subj.missing <- NULL

  for (group in GROUPS) {
    subj.files[[group]] <- list.files(path = '.',
      pattern = glob2rx(paste(PREFIX,
        group, '*fMRIsessiondata.mat', sep = '_')),
      ignore.case = T )

    subj.files[[group]] <- subj.files[[group]] [grepl(x = subj.files[[group]],
      pattern = paste(behav.table[which(behav.table$group == group), 'subj'],
      collapse = '|'))]

    # check if any subjects are missing
    subjs.unique <- unique(behav.table[which(behav.table$group == group), 'subj'])

    # print(subjs.unique)
    # print(behav.table[which(behav.table$group == group), ])
    # print(subj.files[[group]])
    # print(subjs.unique)

    if (length(subj.files[[group]]) < length(subjs.unique)) {
      for (subj in subjs.unique) {
        subj.match <- grep(pattern = subj, x = subj.files[[group]])

        if (!length(subj.match) > 0) {
          subj.missing <- c(subj.missing, subj)
        }

      }
    }
  }

  if (length(subj.missing) > 0) {
    stop.message <- 'Data from the following subjects are missing:'
    stop(paste(stop.message, paste(subj.missing, collapse = ', ')))
  }

  return(subj.files)
}

subj.files <- get.sessionData(PREFIX, GROUPS, behav.table)

##### WRITE: Defining Output Filename #####

# defining the output file name
output.file <- paste0(paste(GROUPS, collapse = '&'),
  '_', paste(VARBS, collapse = '&'), '_analysis.txt')
output.file <- file.path(PATH, output.file)

# defining the results file
results.file <- paste0(paste(GROUPS, collapse = '&'),
  '_', paste(VARBS, collapse = '&'), '_fMRIresult.mat')

print(paste('Writing to ', output.file))

# line seperator
line.sep <- '\n%-----------------------------------------------------\n'

##### WRITE: Group Selection Start #####

write(x = line.sep, file = output.file, append = FALSE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Result File Name Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = paste0('result_file ', results.file), file = output.file, append = TRUE)

write(x = '\n	%%%%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)
write(x =  '	%  Result File Name End  %' , file = output.file, append = TRUE)
write(x =  '	%%%%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Group Section Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

for (group in GROUPS) {
  write(x = paste( c('group_files', subj.files[[group]]) , collapse = ' '), file = output.file, append = TRUE)
}

write(x = '\n	%%%%%%%%%%%%%%%%%%%%%%%', file = output.file, append = TRUE)
write(x =   '	%  Group Section End  %', file = output.file, append = TRUE)
write(x =   '	%%%%%%%%%%%%%%%%%%%%%%%', file = output.file, append = TRUE)

##### WRITE: PLS Section Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  PLS Section Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = paste0('pls          ', PLS_opt  , '    % PLS Option (between 1 to 6, see above notes)\n'   ), file = output.file, append = TRUE)
write(x = paste0('mean_type    ', MEAN_type, '    % Mean-Centering Type (between 0 to 3, see above)\n'), file = output.file, append = TRUE)
write(x = paste0('cormode      ', COR_mode , '    % Correlation Mode (can be 0,2,4,6, see above)\n'   ), file = output.file, append = TRUE)

write(x = paste0('num_perm	 ', num_perm , '    % Number of Permutation'                   ), file = output.file, append = TRUE)
write(x = paste0('num_split  ', num_split, '    % Natasha Perm Split Half'                 ), file = output.file, append = TRUE)
write(x = paste0('num_boot	 ', num_boot , '    % Number of Bootstrap'                     ), file = output.file, append = TRUE)
write(x = paste0('boot_type  ', boot_type, '    % Either strat or nonstrat bootstrap type' ), file = output.file, append = TRUE)
write(x = paste0('clim		   ', clim     , '    % Confidence Level for Behavior PLS'       ), file = output.file, append = TRUE)
write(x = paste0('save_data	 ', save_data, '    % Set to 1 to save stacked datamat\n'      ), file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%'   , file = output.file, append = TRUE)
write(x = '	%  PLS Section End  %'   , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%\n' , file = output.file, append = TRUE)

##### WRITE: Condition Selection Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Condition Selection Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

write(x = paste('selected cond ', CONDS), file = output.file, append = TRUE)

write(x = '\n	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'    , file = output.file, append = TRUE)
write(x =  '	%  Condition Selection End  %'    , file = output.file, append = TRUE)
write(x =  '	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%\n'  , file = output.file, append = TRUE)

##### WRITE: Contrast Data Start #####

write(x = line.sep, file = output.file, append = TRUE)

write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%'  , file = output.file, append = TRUE)
write(x = '	%  Contrast Data Start  %'  , file = output.file, append = TRUE)
write(x = '	%%%%%%%%%%%%%%%%%%%%%%%%%\n', file = output.file, append = TRUE)

if (!is.na(CONTRASTS)) {
  if (CONTRASTS != 'NULL') {
    for (contrast in 1:dim(CONTRASTS)[1]) {
      contrast <- CONTRASTS[contrast, ]
      write(x = paste0( c('contrast_data ', contrast), collapse = ' '), file = output.file, append = TRUE)
    }
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

if (PLS_opt %in% 3:6) {
  print(VARBS)
  for (line in 1:dim(behav.table)[1]) {
    line <- paste('behavior_data', paste(behav.table[line, VARBS], collapse = ' '), collapse = ' ')
    write(x = line, file = output.file, append = TRUE)
  }
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

if (PLS_opt %in% 3:6) {
  write(x = paste( c('behavior_name', VARBS), collapse = ' ' ) , file = output.file, append = TRUE)
}

write(x = '\n	%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)
write(x =  '	%  Behavior Name End  %' , file = output.file, append = TRUE)
write(x =  '	%%%%%%%%%%%%%%%%%%%%%%%' , file = output.file, append = TRUE)

write(x = line.sep, file = output.file, append = TRUE)
