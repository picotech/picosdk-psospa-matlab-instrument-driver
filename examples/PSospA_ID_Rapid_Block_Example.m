%% PicoScope 3000E Series (A API) Instrument Driver Oscilloscope Rapid Block Data Capture Example
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
% PSospA_ID_Rapid_Block_Example, at the MATLAB command prompt.
% 
% The file, PSospA_ID_RAPID_BLOCK_EXAMPLE.M must be on your MATLAB PATH. For
% additional information on setting your MATLAB PATH, type 'help addpath'
% at the MATLAB command prompt.
%
% *Example:*
%     PSospA_ID_Rapid_Block_Example;
%
% *Description:*
%     Demonstrates how to set properties and call functions in order to
%     capture a rapid block run from a PicoScope 3000E (A API) Series Oscilloscope.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2020-2021 Pico Technology Ltd. See LICENSE file for terms.

%% Suggested Input Settings

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

%% Set Device Resolution

resolution = psospaEnumInfo.enPicoDeviceResolution.PICO_DR_10BIT;

[status.setResolution] = invoke(psospaDeviceObj, 'psospaSetDeviceResolution', resolution);

disp('Device Resolution set to 10 bits')

%% Enable Channel A + B
% Disable  other channels
for i = (0:7)
    try
        [status.setChannelOff] = invoke(psospaDeviceObj, 'psospaSetChannelOff', i);
    catch
        
    end 
end

for j = (128:1:131)
    try
        [status.turnDigitalPortOff] = invoke(psospaDeviceObj, 'psospaDigitalPortOff',j);
    catch
    end
end

% Enable channels A + B with +-5 V range with DC coupling and full bandwidth

channelA = psospaEnumInfo.enPicoChannel.PICO_CHANNEL_A;
channelB = psospaEnumInfo.enPicoChannel.PICO_CHANNEL_B;
couplingDC = psospaEnumInfo.enPicoCoupling.PICO_DC;
rangeMin = -5000000000;  %convert voltage being used to nV
rangeMax = 5000000000;
rangeType = psospaEnumInfo.enPicoProbeRangeInfo.PICO_X1_PROBE_NV;
analogueOffset = 0.0; %set value to analogue offset in volts
bandwidth = psospaEnumInfo.enPicoBandwidthLimiter.PICO_BW_20MHZ;

[status.setChannelOn.A] = invoke(psospaDeviceObj, 'psospaSetChannelOn', channelA, couplingDC, rangeMin, rangeMax, rangeType, analogueOffset, bandwidth);
[status.setChannelOn.B] = invoke(psospaDeviceObj, 'psospaSetChannelOn', channelB, couplingDC, rangeMin, rangeMax, rangeType, analogueOffset, bandwidth);

disp('Channels A and B set')

%% Set Simple Trigger

enable = 1;
source = channelA;
threshold = 1000; %mV
direction = psospaEnumInfo.enPicoThresholdDirection.PICO_RISING;
delay = 0;
autoTriggerMicroSeconds = 1000000; %us

[status.setSimpleTrigger] = invoke(psospaDeviceObj, 'psospaSetSimpleTrigger', enable, source, threshold, direction,...
    delay, autoTriggerMicroSeconds);

disp('Simple Trigger set')


%% Get Fastest Timebase

enabledChannelFlags= psospaEnumInfo.enPicoChannelFlags.PICO_CHANNEL_A_FLAGS + psospaEnumInfo.enPicoChannelFlags.PICO_CHANNEL_B_FLAGS;
pTimebase = libpointer('uint32Ptr',0);
pTimeInterval = libpointer('doublePtr',0);

[status.getMinimumTimebaseStateless] = invoke(psospaDeviceObj, 'psospaGetMinimumTimebaseStateless', enabledChannelFlags,...
    pTimebase, pTimeInterval, resolution);

timebase = pTimebase.Value;
timeInterval = pTimeInterval.Value;

%% Set memory segments

nSegments = 10;
nMaxSamples = 10000000;
pnMaxSamples = libpointer('uint64Ptr', nMaxSamples);
[status.memorySegments] = invoke(psospaDeviceObj, 'psospaMemorySegments', nSegments, pnMaxSamples);
    
%% Set number of samples to be collected

numPreTriggerSamples = 1000000;
numPostTriggerSamples = 9000000;
totalSamples = numPreTriggerSamples + numPostTriggerSamples;

%% Set number of captures

[status.setNoOfCaptures] = invoke(psospaDeviceObj, 'psospaSetNoOfCaptures', nSegments);

%% Create Buffers

bufferAMax = zeros(totalSamples, 1, 'int16');
bufferBMax = zeros(totalSamples, 1, 'int16');

for i=(1:10)
    pBufferAMax(i) =libpointer('int16Ptr', bufferAMax);
    pBufferBMax(i) =libpointer('int16Ptr', bufferBMax);
end

dataType = psospaEnumInfo.enPicoDataType.PICO_INT16_T;
downSampleRatioMode = psospaEnumInfo.enPicoRatioMode.PICO_RATIO_MODE_AVERAGE;
actionA = bitor(psospaEnumInfo.enPicoAction.PICO_CLEAR_ALL, psospaEnumInfo.enPicoAction.PICO_ADD);
actionB = psospaEnumInfo.enPicoAction.PICO_ADD;

[status.setBufferA.zero] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(1), ...
    totalSamples, dataType, 0, downSampleRatioMode, actionA);
[status.setBufferB.zero] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(1), ...
    totalSamples, dataType, 0, downSampleRatioMode, actionB);

[status.setBufferA.one] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(2), ...
    totalSamples, dataType, 1, downSampleRatioMode, actionB);
[status.setBufferB.one] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(2), ...
    totalSamples, dataType, 1, downSampleRatioMode, actionB);

[status.setBufferA.two] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(3), ...
    totalSamples, dataType, 2, downSampleRatioMode, actionB);
[status.setBufferB.two] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(3), ...
    totalSamples, dataType, 2, downSampleRatioMode, actionB);

[status.setBufferA.three] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(4), ...
    totalSamples, dataType, 3, downSampleRatioMode, actionB);
[status.setBufferB.three] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(4), ...
    totalSamples, dataType, 3, downSampleRatioMode, actionB);

[status.setBufferA.four] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(5), ...
    totalSamples, dataType, 4, downSampleRatioMode, actionB);
[status.setBufferB.four] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(5), ...
    totalSamples, dataType, 4, downSampleRatioMode, actionB);

[status.setBufferA.five] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(6), ...
    totalSamples, dataType, 5, downSampleRatioMode, actionB);
[status.setBufferB.five] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(6), ...
    totalSamples, dataType, 5, downSampleRatioMode, actionB);

[status.setBufferA.six] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(7), ...
    totalSamples, dataType, 6, downSampleRatioMode, actionB);
[status.setBufferB.six] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(7), ...
    totalSamples, dataType, 6, downSampleRatioMode, actionB);

[status.setBufferA.seven] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(8), ...
    totalSamples, dataType, 7, downSampleRatioMode, actionB);
[status.setBufferB.seven] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(8), ...
    totalSamples, dataType, 7, downSampleRatioMode, actionB);

[status.setBufferA.eight] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(9), ...
    totalSamples, dataType, 8, downSampleRatioMode, actionB);
[status.setBufferB.eight] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(9), ...
    totalSamples, dataType, 8, downSampleRatioMode, actionB);

[status.setBufferA.nine] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferAMax(10), ...
    totalSamples, dataType, 9, downSampleRatioMode, actionB);
[status.setBufferB.nine] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelB, pBufferBMax(10), ...
    totalSamples, dataType, 9, downSampleRatioMode, actionB);

%% Run Block Capture

pTimeIndisposedMs = libpointer('doublePtr',0);
segmentIndex = 0;

disp('Collection starting...')

[status.runBlock] = invoke(psospaDeviceObj, 'psospaRunBlock', numPreTriggerSamples, numPostTriggerSamples,...
    timebase, pTimeIndisposedMs, segmentIndex); 

pReady = libpointer('int16Ptr',0);

while pReady.Value == 0
    [status.IsReady] = invoke(psospaDeviceObj,'psospaIsReady',pReady);
end

disp('Collection finished')

%% Retrieve Data

startIndex = 0;
pSamplesCollected = libpointer('uint64Ptr',totalSamples);
downSampleRatio = 1;
segmentIndex = 0;
pOverflow = libpointer('int16Ptr',zeros(10,1));
fromSegmentIndex = 0;
toSegmentIndex = 9;

[status.getValuesBulk] = invoke(psospaDeviceObj, 'psospaGetValuesBulk', startIndex,...
    pSamplesCollected, fromSegmentIndex, toSegmentIndex, downSampleRatio, downSampleRatioMode, pOverflow);

samplesCollected = pSamplesCollected.Value;

disp('Data Retrieved')

%% Convert Data from ADC counts to mV

BufferAMax={};
BufferBMax={};
for i=(1:10)
    BufferAMax{i} = pBufferAMax(i).Value;
    BufferBMax{i} = pBufferBMax(i).Value;
end

pMinValue = libpointer('int16Ptr',0);
pMaxValue = libpointer('int16Ptr',0);

[status.getAdcLimits] = invoke(psospaDeviceObj, 'psospaGetAdcLimits', resolution, pMinValue, pMaxValue);

minValue = pMinValue.Value;
maxValue = pMaxValue.Value;

voltageRange = 5000; %mV

bufferAMax={};
bufferBMax={};

for i=(1:10)
    bufferAMax{i} = adc2mv(BufferAMax{i},voltageRange,double(maxValue));
    bufferBMax{i} = adc2mv(BufferBMax{i},voltageRange,double(maxValue));
end

disp('Data converted to mV')

%% Plot Collected Data

maxTime = (double(samplesCollected) * timeInterval);
time = linspace(0,maxTime,samplesCollected);

figure(1)
%xlim([min(time) max(time)])
%ylim([-voltageRange voltageRange])
hold on
for i=(1:10)
    plot(time,bufferAMax{i});
    plot(time,bufferBMax{i});
end
ylabel('Voltage (mV)');
xlabel('Time (s)');
hold off

%% Disconnect scope

disconnect(psospaDeviceObj);

%%
delete(psospaDeviceObj);