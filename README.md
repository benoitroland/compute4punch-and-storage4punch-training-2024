# Compute4PUNCH and Storage4PUNCH Training 2024

## Table of contents

The goal of this tutorial is to familiarise yourself with using the Compute4PUNCH and Storage4PUNCH resources.
The first two sections have to be executed on your laptop. Sections 3 to 8 have to be executed on the Compute4PUNCH login node.
More information can be found in the [presentation](./roland-tutorial-bonn.pdf) attached to this tutorial.

1. [The OIDC agent](#section-oidc-agent)
2. [Login to the Compute4PUNCH login node](#section-login-node)
3. [Access Storage4PUNCH from the login node](#section-s4p)
4. [The CERN Open Data Exercise](#section-exercise)
5. [Run your own CERN Open Data Analysis and retrieve the results locally](#section-exercise-locally)
6. [Run your own CERN Open Data Analysis and retrieve the results on Storage4PUNCH](#section-exercise-s4p)
7. [Job monitoring and debugging](#section-monitoring)

## 1. The OIDC agent <a name="section-oidc-agent"></a>

### 1.1 Set up the oidc-agent

If you are using the Compute4PUNCH and Storage4PUNCH infrastructures for the first time, you need to set up the [oidc-agent](https://indigo-dc.gitbook.io/oidc-agent) on your laptop.
The oidc-agent is a command line tool to handle OIDC access tokens and is used to obtain access tokens issued by the Helmholtz AAI provider. The installation of the agent and its configuration
for the Helmholtz AAI provider are described in the section "Install OIDC Agent" in the [Compute4PUNCH documentation](https://intra.punch4nfdi.de/?md=/docs/TA2/WP2/Compute4PUNCH_Documentation_Users.md).
This initial setup only needs to be done once.

### 1.2 Set up the oidc-agent environment

The installation of the oidc-agent environment has to be done every time you want to connect to the login node.

Start the oidc-agent and define the `OIDC_SOCK` environment variable in your shell by executing:

```bash
eval `oidc-agent`
```

Load the `punch-aai` configuration to the `oidc-agent` listening on `$OIDC_SOCKS` by executing:

```bash
oidc-add punch-aai
```

You will be prompted for the password you provided during the initial setup.

### 1.3 OIDC agent command lines

Some useful OIDC agent command lines are presented below. Just give them a try on your laptop.

List available configurations:

```bash
oidc-add --list
```

List loaded configurations:

```bash
oidc-add --load
```

Decrypt and print configuration:

```bash
oidc-add --print punch-aai
```

Generate OIDC access token:

```bash
oidc-token punch-aai
```

## 2. Login to the Compute4PUNCH login node <a name="section-login-node"></a>

The connection to the Compute4PUNCH login node can be established by using the [`mccli`](https://mccli.readthedocs.io/en/latest) client
or the [`oidc-ssh`](https://gitlab-p4n.aip.de/compute4punch/oidc-ssh) wrapper.

### 2.1 Login using mccli

The `mccli` client, developed in EU projects, is a wrapper around the `ssh` client that enables to establish SSH connections with OIDC access tokens.

To obtain the `mccli` client, create and activate a python virtual environment:

```bash
python3 -m venv mccli_venv
source mccli_venv/bin/activate
```
before installing `mccli` using `pip`:

```bash
pip install mccli
```
The connection to the Compute4PUNCH login node `c4p-login.gridka.de` is then established by executing:

```bash
mccli ssh c4p-login.gridka.de
```

### 2.2 Login using oidc-ssh

The `oidc-ssh` wrapper, developed by Oliver Freyermuth and Peter Wienemann (Uni Bonn), offers a second possibility to login to the login node.

The wrapper has dependencies listed in the [`oidc-ssh`](https://gitlab-p4n.aip.de/compute4punch/oidc-ssh) GitLab repository and can be installed using `curl`:

```bash
curl -o /usr/local/bin/oidc-ssh https://gitlab-p4n.aip.de/compute4punch/oidc-ssh/-/raw/main/src/oidc-ssh
```

Change the permission by running:

```bash
chmod +x /usr/local/bin/oidc-ssh
```

Set up the `OIDC_ACCOUNT` environment variable:

```bash
export OIDC_ACCOUNT=punch-aai
```

The connection to the login node can then be established by executing:

```bash
oidc-ssh c4p-login.gridka.de
```

### 2.3 Fix your socket for friendly connections

Add the following function to the `.profile` configuration file on your laptop:

```bash
function OIDCagent() {

  oidc_sock="$HOME/.cache/oidc-agent/oidc-agent.sock"
  export OIDC_SOCK=$oidc_sock

  numagent=$(ps -x | grep oidc-agent | grep -v grep | wc -l)

  if [ ! -S $oidc_sock ] || [ $numagent == 0 ]; then
    oidc-agent --socket-path=$oidc_sock --console > /dev/null 2>&1 &
    sleep 0.1
  fi

  list_config=( $(oidc-add --list | tail -n +1) )

  if [[ ${#list_config[@]} == 0 ]]; then
      echo "Please configure your OIDC account first!"
      return
  elif [[ ${#list_config[@]} == 1 ]]; then
      user_config=${list_config[0]}
  else
      echo ""
      echo "Several OIDC account configurations have been found:"
      echo ""
      for config in "${list_config[@]}"
      do
          echo "$config"
      done
      echo ""
      read -p "Please specify the configuration to be used: " user_config
  fi

  echo ""
  echo "The following configuration will be used: $user_config"
  echo ""

  oidc-add $user_config
}
```

Open a new shell and run the OIDC agent function:

```bash
OIDCagent
```

From now on, you will be able to connect to the Compute4PUNCH login node in the current session without being prompted again for your password.

## 3. Access Storage4PUNCH from the login node <a name="section-s4p"></a>

### 3.1 Set up the oidc-agent on the login node

Connect to the login node using `mccli`by executing:

```bash
mccli ssh c4p-login.gridka.de
```

You now need to set up the [oidc-agent](https://indigo-dc.gitbook.io/oidc-agent) on the login node following the same instructions as the ones you applied to set up the agent on your laptop.
The installation of the agent and its configuration for the Helmholtz AAI provider are described in the section "Install OIDC Agent" in the
[Compute4PUNCH documentation](https://intra.punch4nfdi.de/?md=/docs/TA2/WP2/Compute4PUNCH_Documentation_Users.md). This initial setup only needs to be done once.
The installation of the oidc-agent is required to be able to generate access tokens in order to access the Storage4PUNCH resources from the Compute4PUNCH login node.

### 3.2 DaviX client

The [DaviX](https://davix.web.cern.ch/davix/docs/devel) client is installed on the login node and used to transfer and manage files on the Storage4PUNCH infrastructure using the HTTP
or WebDav protocol. The authentication to Storage4PUNCH is based on Helmholtz AAI access tokens and X509 certificates. The access token is provided to the DaviX client in the "Authorization"
header using the "Bearer" HTTP authentication scheme. To use the DaviX command lines, 3 ingredients are needed, that we will define as environment variables to ease the access to the storage
resources during the duration of your session. Define the storage elements at DESY, KIT, BONN and GSI by executing the following instructions on the login node:

```bash
export DESY_STORAGE=https://dcache-desy-webdav.desy.de:2880//pnfs/desy.de/punch/
export KIT_STORAGE=https://dcache-kit.gridka.de:2880/pnfs/gridka.de/punch4nfdi/
export BONN_STORAGE=https://xrootd.physik.uni-bonn.de:1094/cephfs/grid/helmholtz/
export GSI_STORAGE=https://lxpunch1.gsi.de:1094/
```

Define the X509 certificate directory by running:

```bash
export X509_CERT_DIR=/cvmfs/grid.cern.ch/etc/grid-security/certificates/
```

Generate your access token using the OIDC agent:

```bash
eval `oidc-agent`
```

```bash
oidc-add punch-aai
```

```bash
export BEARER_TOKEN=$(oidc-token punch-aai)
```

List the content of the DESY storage element by running the `davix-ls` command line in the following way:

```bash
davix-ls --capath $X509_CERT_DIR -l -H "Authorization: Bearer $BEARER_TOKEN" $DESY_STORAGE
```

Download the file "PUNCH_logo.png" located at DESY using the `davix-get` command line:

```bash
davix-get --capath $X509_CERT_DIR -H "Authorization:  Bearer $BEARER_TOKEN" $DESY_STORAGE/PUNCH_logo.png PUNCH_logo.png
```

Other DaviX command lines are `davix-put` to upload a file, `davix-mkdir` to create a directory and `davix-rm` to delete a file or a directory.
Their usage is explained in the [Storage4PUNCH documentation](https://intra.punch4nfdi.de/?md=/docs/TA2/WP1/StoragePrototyping.md).
All access tokens being mapped to a single user on the storage resources, you have the possibility to delete files created by other PUNCH users.
You should therefore pay particular attention when you delete some elements.

### 3.3 Scripts to manage Storage4PUNCH

Scripts are available on the login node to manage the storage resources in an easy way. These are `s4p-list-storage.sh`, `s4p-get-storage.sh`, `s4p-mkdir-storage.sh` and `s4p-remove-storage.sh`
to respectively list the content of a storage element, download a file, create a directory, and delete a file or a directory.

List the content of the directory "atlas_opendata_2020" located at KIT by running:

```bash
s4p-list-storage.sh gridka atlas_opendata_2020

```

Download the file "PUNCH_logo.png" located at DESY by executing:

```bash
s4p-get-storage.sh desy PUNCH_logo.png
```

## 4. The CERN Open Data Exercise <a name="section-exercise"></a>

### 4.1 The CERN Open Data and today's goal

Back in 2014 CERN launched the [CERN Open Data Portal](https://opendata.cern.ch) with the aim to make real collision events recorded by various particle physics experiments available to the public. 
Monte Carlo samples used to describe the collision events are made available as well.

_"Launching the CERN Open Data Portal is an important step for our Organization. Data from the LHC programme are among the most precious assets of the LHC experiments, that today we start sharing 
openly with the world. We hope these open data will support and inspire the global research community, including students and citizen scientists"_ - CERN Ex Director-General Rolf Heuer.

You will today take part in analyzing real collisions data recorded by the CMS experiment at the Large Hadron Collider (LHC) at CERN in Geneva back in 2012.
No worry, you do not need to become a particle physicist first. People like Achim Geiser (DESY) took already care to write the necessary analysis code for you.
We will simply show you how to execute it on the Compute4PUNCH infrastructure and how to save the results locally on the submit node and remotely on the Storage4PUNCH resources. 

### 4.2 Material needed

You can find the material needed to execute the CERN Open Data Exercise
in the [CERN_Open_Data_Exercise](https://gitlab-p4n.aip.de/pyatutorials/compute4punch-and-storage4punch-training-2024/-/tree/main/CERN_Open_Data_Exercise) directory of this repository.
It was first set up by Manuel Giffels (KIT) in a [tutorial given in 2022](https://gitlab-p4n.aip.de/compute4punch/tutorials/c4p_tutorial_general_meeting_09_2022) and includes the actual analysis code,
a script to set up the environment and run the analysis code, and a job submission file to run your job on the Compute4PUNCH resources. It has been extended to cover the need of this tutorial.

### 4.3 The actual analysis code `dimuonSpectrum2012_eospublic.C`

We will not walk through the sophicated root analysis description, since we promised you wouldn't have to become a particle physicist first and maybe because particle physicists also put on
their trousers one leg at a time. However, you are of course invited to discover it yourself.

### 4.4 The `run_analysis.sh` script

The `run_analysis.sh` script sets up the environment and actually drives the analysis. In adddition, it prints out some information about the host on which your analysis has been executed
as well as the start and end timestamps of the execution of the analysis code.

```bash
#!/bin/bash

# Print the host environment
echo $(hostname)
cat /proc/cpuinfo

echo "Job Start Time: $(date)"

# Setup ROOT environment for rocky linux 9                                                                                                                                                                
source /cvmfs/sft.cern.ch/lcg/views/LCG_104/x86_64-el9-gcc11-opt/setup.sh

# Run analysis (-q quit after execution, -b batch mode w/o graphics, -x quit in case an exception is thrown)
root -q -b -x dimuonSpectrum2012_eospublic.C+

echo "Job Finshed at $(date)"
```

The script sets up the ROOT environment - needed to run the analysis code - and runs the code afterwards.

### 4.5 The `submit_analysis.jdl` job submission file

The [job submission file](https://htcondor.readthedocs.io/en/23.0/users-manual/submitting-a-job.html) uses the HTCondor job description language (jdl) to specify to the HTCondor batch system
the task you want to execute and the compute resources needed to execute this task. 

```
# The name of the executable
executable = run_analysis.sh

# The Helmholtz AAI provider is used to obtain access tokens
# use_oauth_services = helmholtz

# Where to store log files
output = logs/$(cluster).$(process).out
error = logs/$(cluster).$(process).err
log = logs/cluster.log

# We would like to transfer files to the batch node and later on back to the submit node if your job was successful
ShouldTransferFiles = YES
WhenToTransferOutput = ON_SUCCESS

# What files to transfer
transfer_input_files = dimuonSpectrum2012_eospublic.C
transfer_output_files = dimuonSpectrum2012_C_eospublic.pdf

# Transfer output file to the KIT storage element
# output_destination = helmholtz+https://dcache-kit.gridka.de:2880/pnfs/gridka.de/punch4nfdi/Tutorial-Bonn/your_user_name

# The requirements of your job - Memory is in MBytes
request_cpus = 8
request_memory = 20000

# In which container your job should be executed
+SINGULARITY_JOB_CONTAINER = "wlcg-wn:latest"

# We would like to submit the job only once
queue 1
```

The `executable` that will be run on the Compute4PUNCH infrastructure is the script `run_analysis.sh` that sets up the ROOT environment and runs the actual analysis code `dimuonSpectrum2012_eospublic.C`.
This analysis code needs to be present on the batch node where your job will run, which is ensured by the line:

```
transfer_input_files = dimuonSpectrum2012_eospublic.C
```

The file `dimuonSpectrum2012_C_eospublic.pdf` containing the results of your job is transfered from the batch node back to the login node by the line:

```
transfer_output_files = dimuonSpectrum2012_C_eospublic.pdf
```

It is transfered from the batch node to the Storage4PUNCH infrastructure by the lines (commented in the prodived jdl file):

```
use_oauth_services = helmholtz
output_destination = helmholtz+https://dcache-kit.gridka.de:2880/pnfs/gridka.de/punch4nfdi/Tutorial-Bonn/your_user_name
```

The first line tells the HTCondor batch system to use the Helmholtz AAI provider to obtain access tokens, the second line specifies the storage element where the results should be saved.

The container in which your job will be executed is specified by the line:

```
+SINGULARITY_JOB_CONTAINER = "wlcg-wn:latest"
```

The job will run inside the latest version of the `wlcg-wn` container developed by the Worldwide LHC Computing Grid (WLCG) collaboration.
The containers available to the PUNCH users are retrieved from the CVMFS file system mounted on the batch nodes and on the login node.
You can list the available containers by executing:

```bash
ls /cvmfs/unpacked.cern.ch/gitlab-p4n.aip.de\:5005/compute4punch/container-stacks
```

## 5. Run your own CERN Open Data Analysis and retrieve the results locally <a name="section-exercise-locally"></a>

1) Download the analysis code to the login node `c4p-login.gridka.de`:

```bash
git clone https://gitlab-p4n.aip.de/pyatutorials/compute4punch-and-storage4punch-training-2024
```

2) Submit the analysis job to Compute4PUNCH:

```bash
cd ~/compute4punch-and-storage4punch-training-2024/CERN_Open_Data_Exercise
condor_submit submit_analysis.jdl
```

3) Monitor the progress of your analysis job:

```bash
condor_q
```

4) Check the log files of your job for additional information or errors. You can find them in the `logs` directory. Look for all files that are not called `cluster.log`.

5) Download the output histogram to your laptop once the job is finished:

```bash
mccli scp c4p-login.gridka.de:~/compute4punch-and-storage4punch-training-2024/CERN_Open_Data_Exercise/dimuonSpectrum2012_C_eospublic.pdf .
```

6) Open it with your favorite PDF viewer and enjoy your beautiful di-muon spectrum.

## 6. Run your own CERN Open Data Analysis and retrieve the results on Storage4PUNCH <a name="section-exercise-s4p"></a>

1) Update the job submission file `submit_analysis.jdl` in the following way. Uncomment the lines:

```
use_oauth_services = helmholtz
output_destination = helmholtz+https://dcache-kit.gridka.de:2880/pnfs/gridka.de/punch4nfdi/Tutorial-Bonn/your_user_name
```

and replace the place holder "your_user_name" by your actual user name.

2) Create a directory to store the results on Storage4PUNCH:

```bash
s4p-mkdir-storage.sh gridka Tutorial-Bonn/$USER
```

3) Submit the analysis job to Compute4PUNCH:

```bash
condor_submit submit_analysis.jdl
```

4) Monitor the progress of your analysis job:

```bash
condor_q
```

5) Check that the results have been saved on Storage4PUNCH:

```bash
s4p-list-storage.sh gridka Tutorial-Bonn/$USER
```

6) Download the output histogram from Storage4PUNCH to the submit node and to your laptop:

```bash
s4p-get-storage.sh gridka Tutorial-Bonn/$USER/dimuonSpectrum2012_C_eospublic.pdf
```

```bash
mccli scp c4p-login.gridka.de:~/compute4punch-and-storage4punch-training-2024/CERN_Open_Data_Exercise/dimuonSpectrum2012_C_eospublic.pdf .
```

## 7. Job monitoring and debugging <a name="section-monitoring"></a>

Monitor the progress of your job and retrieve its "JOB_ID":

```bash
condor_q
```

Show the matching between job and resources:

```bash
condor_q -better-analyze JOB_ID
```

Show all information related to your job:

```bash
condor_q -long JOB_ID
```

If your job is in the "hold" state, you can see the hold reason by running:

```bash
condor_q -hold JOB_ID 
```

Connect to the batch node running your job:

```bash
condor_ssh_to_job JOB_ID
```



