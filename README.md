# drone-dataflow
Drone Dataflow - A MATLAB toolbox for processing images captured by a UAV

## Requirements
* MATLAB 2018a or newer with the following toolboxes:
    * Optimization Toolbox
    * Mapping Toolbox
    * Image Processing Toolbox
    * Statistics and Machine Learning Toolbox
    * Aerospace Toolbox
* ExifTool (https://www.sno.phy.queensu.ca/~phil/exiftool/)
    * **Note**: ExifTool is used for reading metadata from the images. E.g. GPS position.

## Installation
1. Download and unzip the toolbox: https://github.com/anderskm/drone-dataflow/archive/master.zip
2. Download and install ExifTool (https://www.sno.phy.queensu.ca/~phil/exiftool/)
3. Start MATLAB in the folder, where you unzipped the toolbox.
4. Write "dronedataflow" in the command window to open the Drone Dataflow toolbox GUI.
5. Select the desired task and follow the instructions.
    * **Note**: Check MATLABs command window for progress and details.
    * **Note**: The first time ExifTool is called, you will be prompted to locate it on your pc.
