%% PicoScope 3000E Series (A API) Instrument Driver Oscilloscope Streaming Data Capture Example
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
% PSospA_ID_Streaming_Example, at the MATLAB command prompt.
% 
% The file, PSospA_ID_STREAMING_EXAMPLE.M must be on your MATLAB PATH. For
% additional information on setting your MATLAB PATH, type 'help addpath'
% at the MATLAB command prompt.
%
% *Example:*
%     PSospA_ID_Streaming_Example;
%
% *Description:*
%     Demonstrates how to set properties and call functions in order to
%     stream data from a PicoScope 3000E (A API) Series Oscilloscope.
%
% *See also:* <matlab:doc('icdevice') |icdevice|> | <matlab:doc('instrument/invoke') |invoke|>
%
% *Copyright:* © 2021 Pico Technology Ltd. See LICENSE file for terms.

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

disp('Channels A set')

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

%% Set number of samples to be collected

numPreTriggerSamples = 100000;
numPostTriggerSamples = 900000;
totalSamples = numPreTriggerSamples + numPostTriggerSamples;

%% Create Buffers

maxBuffers = 10;

bufferA = zeros(totalSamples, 1,'int16');

for i =(1:maxBuffers)
    pBufferA(i,1) =libpointer('int16Ptr', bufferA);
end


dataType = psospaEnumInfo.enPicoDataType.PICO_INT16_T;
waveform = 0;
downSampleRatioMode = psospaEnumInfo.enPicoRatioMode.PICO_RATIO_MODE_AVERAGE;
actionA = bitor(psospaEnumInfo.enPicoAction.PICO_CLEAR_ALL, psospaEnumInfo.enPicoAction.PICO_ADD);
actionB = psospaEnumInfo.enPicoAction.PICO_ADD;


[status.setBufferA] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferA(1,1), ...
    totalSamples, dataType, waveform, downSampleRatioMode, actionB);


%% Run Streaming Capture

sampleInterval = 1;
sampleIntervalTimeUnits = psospaEnumInfo.enPicoTimeUnits.PICO_US;
autoStop = 0;
downSampleRatio = 1;

disp('Streaming starting...')

[status.runStreaming] = invoke(psospaDeviceObj, 'psospaRunStreaming', sampleInterval, sampleIntervalTimeUnits,...
    numPreTriggerSamples, numPostTriggerSamples, autoStop, downSampleRatio, downSampleRatioMode);

streamData = psospaStructs.tPicoStreamingDataInfo.members;

streamData.bufferIndex_ = 0;
streamData.channel_ = channelA;
streamData.mode_ = downSampleRatio;
streamData.noOfSamples_ = 0;
streamData.overflow_ = 0;
streamData.startIndex_ = 0;
streamData.type_ = dataType;

pStreamData = libpointer('tPicoStreamingDataInfoPtr',streamData);

streamTrigger = psospaStructs.tPicoStreamingDataTriggerInfo.members;
streamTrigger.triggerAt_=0;
streamTrigger.triggered_=0;
streamTrigger.autoStop_=0;

pStreamTrigger = libpointer('tPicoStreamingDataTriggerInfoPtr',streamTrigger);

i=1

needBufferStatus = hex2dec('197');

while i <= maxBuffers
    
    pause(1)

    [status.getStreamingLatestValues] = invoke(psospaDeviceObj, 'psospaGetStreamingLatestValues', pStreamData, 1, pStreamTrigger);
    
    if status.getStreamingLatestValues ~= PicoStatus.PICO_OK
        bufferA(:,i) = pBufferA(i,1).Value;
        i=i+1;
        if i <= maxBuffers
        [status.setBufferA] = invoke(psospaDeviceObj, 'psospaSetDataBuffer', channelA, pBufferA(i,1), ...
    totalSamples, dataType, waveform, downSampleRatioMode, actionB);
        i
        end
    end
        
end

disp('Streaming finished')

%% Convert Data from ADC counts to mV

pMinValue = libpointer('int16Ptr',0);
pMaxValue = libpointer('int16Ptr',0);

[status.getAdcLimits] = invoke(psospaDeviceObj, 'psospaGetAdcLimits', resolution, pMinValue, pMaxValue);

minValue = pMinValue.Value;
maxValue = pMaxValue.Value;

voltageRange = 5000; %mV

bufferA = adc2mv(bufferA,voltageRange,double(maxValue));

disp('Data converted to mV')

%% Plot Collected Data

samplesCollected=length(bufferA(:,1));
maxBufferTime = (double(samplesCollected) * sampleInterval);
bufferTimeUS = linspace(0,maxBufferTime,samplesCollected);

figure(1)

hold on
for i = 1:maxBuffers
    plot(bufferTimeUS, bufferA(:,i));
end

ylabel('Voltage (mV)');
xlabel('Time (us)');
hold off

totalBuffers = [];
for i = 1:maxBuffers
    totalBuffers = vertcat(totalBuffers,bufferA(:,i));
end

totalSamplesCollected = length(totalBuffers(:,1));
maxTime = (double(totalSamplesCollected) * sampleInterval);
totalTimeUS = linspace(0,maxTime,totalSamplesCollected);

figure(2)

plot(totalTimeUS,totalBuffers);
ylabel('Voltage (mV)');
xlabel('Time (us)');

%% Disconnect scope

disconnect(psospaDeviceObj);

%%

delete(psospaDeviceObj);