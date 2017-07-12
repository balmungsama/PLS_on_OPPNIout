#!/bin/bash
#$ -S /bin/bash
#$ -cwd
#$ -M hpc3586@localhost
#$ -m be
#$ -q abaqus.q
#$ -o /home/hpc3586/JE_packages/PLS_on_OPPNIout/logs/analyze_erfmri_batch.out
#$ -e /home/hpc3586/JE_packages/PLS_on_OPPNIout/logs/analyze_erfmri_batch.err

use matlab

matlab -r "run('/home/hpc3586/JE_packages/PLS_on_OPPNIout/analyze_pls.m')" -nodesktop -nosplash
