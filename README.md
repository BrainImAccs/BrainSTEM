# Brainimaccs System That Executes Modules (BrainSTEM)

This package contains the base layer for other components of the Brain Imaging Accessoires (BrainImAccs) toolkit, i.e. tools and functions for receiving, handling and sending DICOM files. It is meant to be run on a Linux server to receive DICOM files from the Picture Archiving and Communication System (PACS) or modalities, process the scans in a parallel fashion and then export the results back to the PACS.

Different [modules](https://github.com/brainimaccs/brainstem#modules) (i.e. accessoires) are available. After successful installation, these modules can be run directly on folders containing DICOM studies. It is not a requirement to receive the studies e.g. from the PACS.

Please note, that this software is research-only.

# Receiving DICOM files and queueing system

Two queues can bet set up, a `short` queue for quick calculations (e.g. [fatbACPC](https://github.com/BrainImAccs/fatbACPC)), and a `long` queue for longer calculations (e.g. [veganbagel](https://github.com/BrainImAccs/veganbagel)).

`storescp` from `DCMTK` is used to receive DICOM files (see `incoming/incoming-{short,long}.bash`). As soon as a study has been received, `storescp` calls `received-{short,long}.bash` to separate the study into single series, if necessary, and submit those to a work queue. The work queue is based on `parallel` (see `received/queue-{short,long}.bash`), so that a configurable number of series (see `setup.brainstem.bash`) can be processed simultaneously. In the end, the jobs are started by [tools/startJob.bash](https://github.com/brainimaccs/brainstem#assign-jobs-to-queue).

Either your PACS can be set up to send DICOM series to the `storescp` node, or you could use the Query/Retrieve approach (see `movescu-{short,long}.bash`). The latter script takes a Series Instance UID as an argument to query the PACS, which then sends the series to the `storescp` node. `contrib/` has a very simple example, which was used to test the `movescu` approach based on automated HTTP GET requests.

# Installation

## Requirements

We are listing the software versions we used (likely the latest available during development), but we are currently not aware that we rely on any features that are specific to one of the software's versions.

* [BASH](https://www.gnu.org/software/bash/), we used v4.4.19(1)
* [bc](https://www.gnu.org/software/bc/), we used v1.07.1
* [dcm2niix](https://github.com/rordenlab/dcm2niix), we used v1.0.20180622
* [DCMTK](https://dicom.offis.de/dcmtk), we used v3.6.3
* [nifti2dicom](https://github.com/biolab-unige/nifti2dicom), we used v0.4.11
* [med2image](https://github.com/FNNDSC/med2image), we used v1.1.2
* [parallel](https://www.gnu.org/software/parallel/), we used v20180822

## Installation

Do not run BrainImAccs as root. Create a separate user or use an existing one.

Clone the repository

```bash
$ git clone https://github.com/BrainImAccs/BrainSTEM.git
$ cd BrainSTEM
$ git submodule init
$ git submodule update
```

# Modules

Modules are developed separately (each with their own repository), and are integrated into brainstem using GIT submodules. Currently, only two are available:

* [fatbACPC](https://github.com/brainimaccs/fatbACPC): Fully automatic tilting of brainscans to Anterior Commissure - Posterior Commissure line
* [veganbagel](https://github.com/brainimaccs/veganbagel): Volumetric estimation of gross atrophy and brain age longitudinally

**PLEASE NOTE**: Each module needs to be _configured separately_! See the README.md of each repository.

# Configuration

Copy the setup templates:

```bash
$ cp setup.brainstem.bash-template setup.brainstem.bash
```

If you wish to use the DICOM receive/send functionality, you will only need to update the DICOM/PACS communication options in `setup.brainstem.bash`:

```bash
# PACS communication
#
called_aetitle="CALLING"
calling_aetitle_short="CALLED_SHORT"
calling_aetitle_long="CALLED_LONG"
peer="127.0.0.1"
port="1234"

# Start the DICOM receiver on the following port
listening_port_short=10104
listening_port_long=10105
```

You may want to adjust the number of job slots for the `parallel` processing queue based on the number of CPU cores available:

```bash
# Number of jobs to start in parallel in a queue
#
jobSlots=4
```

Do check the rest of the configuration options for potential changes you want to make.

## Assign jobs to queue

```bash
$ cp tools/startJob.bash-template tools/startJob.bash
```

Edit `tools/startJob.bash` to assign jobs to the respective queues by uncommenting the respective lines.

# Running

Run the following commands as the non-root user you are using for BrainImAccs.

```bash
# Start the "short" queue
$ received/queue-short.bash
# Start the DICOM receiver
$ incoming/incoming-short.bash

# Start the "long" queue
$ received/queue-long.bash
# Start the DICOM receiver
$ incoming/incoming-long.bash
```

Now configure your PACS to send images to the DICOM receiver running on your server, send an image and wait for the response.

After being processed in the `incoming/` folder, the received series will be moved to `received/` and processed. After processing, most files will be removed, except for the reference DICOM file, which is used to synchronize DICOM tags between the original and aligned series, and some results from the alignment process.

# Debugging

A number of log files are created:

* DICOM receiver (`storescp`): `incoming/{short,long}.log`
* `parallel` work queue: `received/parent-{short,long}.log`
* `parallel --joblog`: `received/{short,long}-queue.log`
* Log for each job: `received/{short,long}/<datetime of job>/<series>/log`  
  * In order to generate debug job logs, add the `--debug` switch to the module's call in `tools/startJob.bash`.
  * Show the debug log in a less verbose style: `grep -vE "^[+' ]" received/{short,long}/<datetime of job>/<series>/log`

# Acknowledgements

The main scripts are based on the [BASH3 Boilerplate](http://bash3boilerplate.sh).