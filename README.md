# Brain Imaging Accessoires: Brainstem

This package contains the base layer for other components of the Brain Imaging Accessoires toolkit, i.e. tools and functions for receiving, handling and sending DICOM files. It is meant to be run on a Linux server to receive DICOM files from the Picture Archiving and Communication System (PACS) or modalities, process the scans in a parallel fashion and then export the results back to the PACS.

# Receiving DICOM files and queueing system

`storescp` from `DCMTK` is used to receive DICOM files (see `incoming/incoming-short.bash`). As soon as a study has been received, `storescp` calls `received-short.bash` to separate the study into single series, if necessary, and submit those to a work queue. The work queue is based on `parallel` (see `received/queue-short.bash`), so that a configurable number of series (see `setup.brainstem.bash(-template)`) can be processed simultaneously.

Either your PACS can be set up to send DICOM series to the `storescp` node, or you could use the Query/Retrieve approach (see `movescu-short.bash`). The latter script takes a Series Instance UID as an argument to query the PACS, which then sends the series to the `storescp` node. `contrib/` has a very simple example, which was used to test the `movescu` approach based on automated HTTP GET requests.

# Installation

## Requirements

We are listing the software versions we used (likely the latest available during development), but we are currently not aware that we rely on any features that are specific to one of the software's versions.

* [BASH](https://www.gnu.org/software/bash/), we used v4.4.19(1)
* [bc](https://www.gnu.org/software/bc/), we used 1.07.1
* [dcm2niix](https://github.com/rordenlab/dcm2niix), we used v1.0.20180622
* [DCMTK](https://dicom.offis.de/dcmtk), we used v3.6.3
* [nifti2dicom](https://github.com/biolab-unige/nifti2dicom), we used v0.4.11
* [parallel](https://www.gnu.org/software/parallel/), we used v20180822

## Installation

Create an user for the BrainIAccs tools and switch to it.

```bash
$ useradd -m -s /bin/bash brainiaccs
$ su - brainiaccs
```

Clone the repository

```bash
$ cd /path/to/brainiaccs # This folder is going to serve as the installation folder for brainstem (in a subdir) and BrainIAccs tools
$ git clone https://github.com/brainimaccs/brainstem.git
$ cd brainstem
```

# Configuration

Copy the setup templates:

```bash
$ cp setup.brainstem.bash-template setup.brainstem.bash
```

You will only need to update the DICOM/PACS communication options in `setup.brainstem.bash`:

```bash
# PACS communication
#
called_aetitle="CALLING"
calling_aetitle_short="CALLED"
peer="127.0.0.1"
port="1234"

# Start the DICOM receiver on the following port
listening_port_short=10104
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

Edit `tools/startJob.bash` to assign jobs to the respective queues (at the moment, there is only one queue: `short`) by uncommenting the respective lines.

# Running

Run the following commands as the user you created during installation.

```bash
# Start the "short" queue
$ received/queue-short.bash
# Start the DICOM receiver
$ incoming/incoming-short.bash
```

Now configure your PACS to send images to the DICOM receiver running on your server, send an image and wait for the response.

After being processed in the `incoming/` folder, the received series will be moved to `received/` and processed. After processing, most files will be removed, except for the reference DICOM file, which is used to synchronise DICOM tags between the original and aligned series, and some results from the alignment process.

# Debugging

A number of log files are created:

* DICOM receiver (`storescp`): `incoming/short.log`
* `parallel` work queue: `received/parent-short.log`
* `parallel --joblog`: `received/short-queue.log`
* Debug log for each job (probably most interesting): `received/short/<datetime of job>/<series>/log`  
  * Show the log in a less verbose style: `grep -vE "^[+' ]" received/short/<datetime of job>/<series>/log`

# Acknowledgements

The main scripts are based on the [BASH3 Boilerplate](http://bash3boilerplate.sh).
