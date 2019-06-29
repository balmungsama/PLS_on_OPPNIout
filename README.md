# PLS_on_OPPNIout
This package is designed to run a PLS analysis on OPPNI-preprocessed fMRI data.

The entire package can be run using the `write_batch.sh` file, which acts as a wrapper for all other scripts in this package. A few user-specified inputs allow for the fast creation of PLS batch text files, to be used in the PLS package developed by Randy McIntosh (see https://www.rotman-baycrest.on.ca/index.php?section=84).

write_batch.sh accepts the following input parameters:

  -i OPPNI_DIR: The absolute file path to the oppni-preprocessed imaging data
  
  -o OUTPUT: Where the user would like the PLS batch files to be output
  
  -p PREFIX: The prefix for the session file & datamat file 
  
  -b BRAIN_ROI: This can be either a single number (a probability threshold to determine what is and isn't brain, done on a per-subject basis) or a path to a brain mask file. The latter option is generally recommended, especially when performing an analysis with multiple subjects (or multiple runs, analyzed independently), as it is necessary that all brains contain the same number of voxels to be analyzed.
  
  -a ACROSS_RUNS: A binary option, where 1 indicates the data should be merged across runs, while 0 indicates that the analysis will be done within runs
  
  -m A binary option. Do you want a seperate batch-file to be produced for each run (0)? Or would you prefer all subject runs to be done in a single batch (1)?
  
  -s SINGLE_SUBJ: 1 for single-subject analysis, 0 for normal analysis
  -f NORM_REF: 1 for single-subject analysis, 0 for normal analysis
  -r REF_ONSET: a number indicating the reference scan to be used for all conditions
  -n REF_NUM: A number indicating how many reference scans should be used.
  -t NORMAL: Normalize the volume mean (keep 0 unless necessary; see (PLS Documentation)[https://www.rotman-baycrest.on.ca/index.php?section=100] for details)
  
  -z RUN: Would you like to run the analysis after creation of the batch files? ('true' or 'false')
