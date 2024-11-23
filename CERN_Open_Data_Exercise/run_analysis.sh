#!/bin/bash

# Print the environment
echo $(hostname)
cat /proc/cpuinfo

echo "Job Start Time: $(date)"

# Setup ROOT environment for rocky linux 9                                                                                                                                                                
source /cvmfs/sft.cern.ch/lcg/views/LCG_104/x86_64-el9-gcc11-opt/setup.sh

# Run analysis (-q quit after execution, -b batch mode w/o graphics, -x quit in case an exception is thrown)
root -q -b -x dimuonSpectrum2012_eospublic.C+

echo "Job Finshed at $(date)"
