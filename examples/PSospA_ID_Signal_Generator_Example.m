%% PicoScope 3000E Series (A API) Instrument Driver Oscilloscope Signal Generator Example
% This is an example of an instrument control session using a device 
% object. The instrument control session comprises all the steps you 
% are likely to take when communicating with your instrument. 
%       
% These steps are:
%    
% # Create a device object   
% # Connect to the instrument 
% # Configure properties 
% # Invoke functions 
% # Disconnect from the instrument 
%
% To run the instrument control session, type the name of the file,
% PSospA_ID_Signal_Generator_Example, at the MATLAB command prompt.
% 
% The file, PSospA_ID_SIGNAL_GENERATOR_EXAMPLE.M must be on your MATLAB PATH. For
% additional information on setting your MATLAB PATH, type 'help addpath'
% at the MATLAB command prompt.
%
% *Example:*
%     PSospA_ID_Signal_Generator_Example;
%
% *Description:*
%     Demonstrates how to set properties and call functions in order to
%     output from the signal generator of a PicoScope 3000E (A API) Series Oscilloscope.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2020-2022 Pico Technology Ltd. See LICENSE file for terms.

%% Clear Command Window and Close Figures

clc;
close all;

%% Load Configuration Information

[psospaStructs, psospaEnumInfo]=PSospaSetConfig();

%% Device Connection

% Check if an Instrument session using the device object 'psospDeviceObj'
% is still open, and if so, disconnect if the User chooses 'Yes' when prompted.
if (exist('psospaDeviceObj', 'var') && psospaDeviceObj.isvalid && strcmp(psospaDeviceObj.status, 'open'))
    
    openDevice = questionDialog(['Device object psospaDeviceObj has an open connection. ' ...
        'Do you wish to close the connection and continue?'], ...
        'Device Object Connection Open');
    
    if (openDevice == PicoConstants.TRUE)
        
        % Close connection to device
        disconnect(psospaDeviceObj);
        delete(psospaDeviceObj);
        
    else

        % Exit script if User selects 'No'
        return;
        
    end
    
end

%% Create a device object. 
% The serial number can be specified as a second input parameter.

psospaDeviceObj = icdevice('picotech_psospa_generic.mdd','');

%% Connect scope

connect(psospaDeviceObj)

%% Setup scope to output 2 Vpp 10 kHz Sine wave

% set waveform type to sine wave
waveType = psospaEnumInfo.enPicoWaveType.PICO_SINE;
totalSamples = 1000000;
buffer = zeros(totalSamples, 1, 'int16');
bufferLength = uint64(length(buffer));

[status.sigGenWaveform] = invoke(psospaDeviceObj,'psospaSigGenWaveform',waveType, buffer, bufferLength);

% set output voltage to 2 V peak to peak with 0 V offset
peakToPeakVolts = 2;
offsetVolts = 0;
[status.sigGenRange] = invoke(psospaDeviceObj, 'psospaSigGenRange', peakToPeakVolts,offsetVolts);

% set output frequency
frequency = 1000; %Hz

[status.sigGenFrequency] = invoke(psospaDeviceObj, 'psospaSigGenFrequency',frequency);

% apply sign generator settings and start generation

sigGenEnabled = 1;  
sweepEnabled = 0;   
triggerEnabled = 0; 
pFrequency = libpointer('doublePtr',frequency);
stopFrequency = frequency;
pStopFrequency = libpointer('doublePtr',stopFrequency);
frequencyIncrement = 1;
pFrequencyIncrement = libpointer('doublePtr',frequencyIncrement);
dwellTime = 1;
pDwellTime = libpointer('doublePtr',dwellTime);

[status.sigGenApply] = invoke(psospaDeviceObj, 'psospaSigGenApply', sigGenEnabled, sweepEnabled, triggerEnabled, pFrequency, pStopFrequency, pFrequencyIncrement, pDwellTime);



pause(5)

%% change frequency to 100 kHz

frequency = 100000; %Hz
pFrequency = libpointer('doublePtr',frequency);

[status.sigGenFrequency] = invoke(psospaDeviceObj, 'psospaSigGenFrequency',frequency);

% apply changes
[status.sigGenApply] = invoke(psospaDeviceObj, 'psospaSigGenApply', sigGenEnabled, sweepEnabled, triggerEnabled,  pFrequency, pStopFrequency, pFrequencyIncrement, pDwellTime);

pause(5)

%% sweep frequency from 100 kHz to 1 mHz over ~1 s

stopFrequency = 1000000;
frequencyIncrement = 10000;
dwellTime = 0.01;
sweepType = psospaEnumInfo.enPicoSweepType.PICO_UPDOWN;

[status.sigGenFrequencySweep] = invoke(psospaDeviceObj,'psospaSigGenFrequencySweep',stopFrequency,frequencyIncrement,dwellTime,sweepType);

% apply changes
sweepEnabled = 1;
pStopFrequency = libpointer('doublePtr',stopFrequency);
pFrequencyIncrement = libpointer('doublePtr',frequencyIncrement);
pDwellTime = libpointer('doublePtr',dwellTime);
[status.sigGenApply] = invoke(psospaDeviceObj, 'psospaSigGenApply', sigGenEnabled, sweepEnabled, triggerEnabled, pFrequency, pStopFrequency, pFrequencyIncrement, pDwellTime);

pause(5)

%% change wave type to square and stop sweeping

waveType = psospaEnumInfo.enPicoWaveType.PICO_SQUARE;

[status.sigGenWaveform] = invoke(psospaDeviceObj,'psospaSigGenWaveform',waveType, 0,0);

% apply changes
sweepEnabled = 0;
[status.sigGenApply] = invoke(psospaDeviceObj, 'psospaSigGenApply', sigGenEnabled, sweepEnabled, triggerEnabled, pFrequency, pStopFrequency, pFrequencyIncrement, pDwellTime);

pause(5)


%% get max value for arbitrary buffer

maxValue = 0;
minValue = 0;
maxValuePtr = libpointer('doublePtr',maxValue);
minValuePtr = libpointer('doublePtr',minValue);
step = 0;
stepPtr = libpointer('doublePtr',step);
status.sigGenLimits = invoke(psospaDeviceObj, 'psospaSigGenLimits',psospaEnumInfo.enPicoSigGenParameter.PICO_SIGGEN_PARAM_SAMPLE,minValuePtr,maxValuePtr,stepPtr);

maxValue = maxValuePtr.Value;

%% create an arbitary waveform

bufferLength = 30000;
x = 0:(2*pi)/(bufferLength - 1):2*pi;
y = (normalise(sin(x) + sin(2*x)))*maxValue;

buffer = libpointer('int16Ptr',y);

%% set signal generator output arbitary waveform

waveType = psospaEnumInfo.enPicoWaveType.PICO_ARBITRARY;

[status.sigGenWaveform] = invoke(psospaDeviceObj,'psospaSigGenWaveform',waveType, buffer, bufferLength);

% apply changes
sweepEnabled = 0;
[status.sigGenApply] = invoke(psospaDeviceObj, 'psospaSigGenApply', sigGenEnabled, sweepEnabled, triggerEnabled, pFrequency, pStopFrequency, pFrequencyIncrement, pDwellTime);

pause (5)
%% Disconnect scope

disconnect(psospaDeviceObj);

%%
delete(psospaDeviceObj);
