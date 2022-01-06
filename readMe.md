# Tracker

Tracker is a small MATLAB script used to measure 

## System requirements

The program was run on computer with Windows 10 using MATLAB 2018a or more recent. We recommend 16 GB of RAM minimun.

## Installation

Put the script in folder include in your MATLAB search path, add the file directly to your search path : 

```MATLAB
addpath('C:\Users\[username]\[...]\tracker.m')
```

## Usage

1) Put all the TIFF files in a subfolder named "stacks" in a dedicated folder.

2) Call the MATLAB function tracker precising the path to the dedicated folder containing the "stacks" subfolder as a argument. 

```MATLAB
tracker2("C:\Users\[username]\[...]\experiementFolder")
```

3) If the borders were not registered before or are not loaded, the program will prompt you to point the 2 positions of the edge of the pillars for each stack found in the folder. These positions correspond to the edges of the pillar that would be tracked. Point the **first the inside edge of the left pillar**, and **then the inside edge of the right pillars** (see image below to identify the postion to click). The program automatically open the next image. 

![In red, the initial position of the the inside edge of the left pillar, in green the the inside edge of the right pillar.](https://github.com/Orion38/Pillar-tracker/blob/main/assets/images/initPosition.PNG)

N.B. : The order of treatment of each TIFF file depends on the creation date of the file, starting with the oldest.

## Expected results
 Once the program launched The measure the shortening of distances on each image of the stack. An example for the expected results can be found in */expectedResults*. For each stack, the script return : 

- A graph of the variation of distance between the two pillars inside edges for each image of the stack (time step). The graph is also saved in *experiementFolder/figures/diff.fig*

- A *.xls* table containing in each column, the name of each TIFF file in the first line, the "Gap" (distance between the two pillars inside edges on the first image in pixel) in the second line of the and the variations of this distance in pixel over each image in the lines 4 to the end

- In the folder *experiementFolder/save/*, a file *lastBords.mat* with the last tracking position for each file and *lastDiff.mat* containing 2 variables Gap and Diff corresponding to the Gap of each file and the variation of distance in pixel relative to Gap for each image. 

- In the folder *experiementFolder/stacks/check/*, a stack with a name corresponding to each original file name in *experiementFolder/stacks/* with a color line on each pillar as tracked (allow manual validation of the results). 

## Demo

Refer to the instructions above in Usage to reproduce results on the test set.

Please find the expected ouput in */expectedResults*

The typical processing time of the test subset (3 stacks of 27 images each) on a "normal" desktop computer is less than 30 seconds.

## Detailed description of functionnalities

For each stack provided, the script ask for the 2 positions of the inside edges to be tracked on the first image. It then reduces the image to its average horizontal profile and associate to the 2 
positions a patch of the corresponding profile. On each average horizontal profile of each image of the stack, for both patches, it searches the new position by identifying where the patch of 
profile best correlates to the new image profile. It then saves the distance between the two positions and compares it to the initial distance between the two pillars. 

In the *tracker.m* file, several parameters can be adjusted : 

- *interpolation_factor* allow to increase the resolution of measurement by interpolating the profiles by an integer factor.

- If *sav* is an integer >0, it saves the *check stacks* (see *expected results*), saving 1 in image every *sav* images comapred to the initial stack.

- *loadBoardes* is 0 or 1. If *loadBoardes* is equal to one and previous pillars edges were selected for the stacks, the program load these poistions.

- *skip_tracking* imposed the program to skip the tracking if it is equal to one (will display previously computed results instead).

- *chk_bord* will display the calculated line profile during the edges selection to help identify the maximum contrast areas.

- If *saveTable" is equal to one, the script will save the results as an *.xls* file.

- If *dis* is equal to one, the script will display the figure after the computation.

- *nbImgBefore* is an integer corresponding to the number of images to average to for the reference image/line profile to choose the position and track the edges. 


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

This work is licensed under a Creative Commons Attribution 4.0 International License. https://creativecommons.org/licenses/by/4.0/