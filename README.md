# PicoScope 3000E Series - MATLAB Generic Instrument Driver

This MATLAB<sup>®</sup> Generic Instrument Driver allows you to acquire data from the PicoScope<sup>®</sup> 3000E Series oscilloscopes and control built-in signal generator functionality. The data could be processed in MATLAB using functions from Toolboxes such as [Signal Processing Toolbox](https://www.mathworks.com/products/signal.html). 

The driver has been created using Instrument Control Toolbox (TBC). 

This Instrument Driver package includes the following: 

* The MATLAB Generic Instrument Driver 
* Example scripts that demonstrate how to call functions in order to capture data in various collection modes, as well as using the signal generator.

The driver can be used with the Test and Measurement Tool to carry out the following: 

  * Acquire data in Block mode 
  * Acquire data in Rapid Block mode 
  * Use the Built-in Function/Arbitrary Waveform Generator (model-dependent)

## Supported Models

The driver will work with the following PicoScope models:
    
    * 3000E Scopes

## Getting started

### Prerequisites

* [MATLAB](https://uk.mathworks.com/products/matlab.html) for Microsoft Windows or Linux operating systems.
* [Instrument Control Toolbox](http://www.mathworks.co.uk/products/instrument/)
* The [PicoScope Support Toolbox](http://uk.mathworks.com/matlabcentral/fileexchange/53681-picoscope-support-toolbox)

**Currently with this release only 64-bit MATLAB on Windows is supported.  Support for other operation systems will come in further updates.**

### Installing the Instrument Driver files

We recommend using the [Add-Ons Explorer](https://uk.mathworks.com/help/matlab/matlab_env/get-add-ons.html) in MATLAB in order to install these files and obtain updates.

If your version of MATLAB does not have the Add-Ons Explorer, download the zip file from the [MATLAB Central File Exchange page]()
 and add the root and subfolders to the MATLAB path.

### Installing drivers

Drivers are available for the following platforms. Refer to the subsections below for further information.

#### Windows

* Download the PicoSDK 64-bit driver package installer from our [Downloads page](https://www.picotech.com/downloads).

#### Linux

* Follow the instructions on our [Linux Software & Drivers for Oscilloscopes and Data Loggers page](https://www.picotech.com/downloads/linux) to install the required `libpsospa` and `libpswrappers` driver packages.

## Obtaining support

Please visit our [Support page](https://www.picotech.com/tech-support) to contact us directly or visit our [Test and Measurement Forum](https://www.picotech.com/support/forum71.html) to post questions.

Please leave a comment and rating for this submission on our [MATLAB Central File Exchange page]().

## Versioning

For the versions available, and release notes, refer to the [Releases](https://github.com/picotech/picosdk-psospa-matlab-instrument-driver/releases) page.

## Copyright and licensing

See [LICENSE.md](LICENSE.md) for license terms. 

*PicoScope* is a registered trademark of Pico Technology Ltd. 

*MATLAB* is a registered trademark of The Mathworks, Inc. *Instrument Control Toolbox* and *Signal Processing Toolbox*
are trademarks of The Mathworks, Inc.

*Windows* is a registered trademark of Microsoft Corporation. 

*Linux* is the registered trademark of Linus Torvalds in the U.S. and other countries.

Copyright © 2024 Pico Technology Ltd. All rights reserved. 

