%% Plotting Power
close all
freqRangeAll=[0,4]; % frequency range to average
freq_list={'delta'};
color={'k','b','g','r'};
chans2plot=[6,7,8]
load('sample/testProcessedData/powerdata.mat')
studyVarsFilename = 'sample/testProcessedData/parameters.mat'; % study vars to load in
load(studyVarsFilename)
%% This compares different conditions. Each Trial and freq is done seperatly
% Only things that are modular are frequency, color, and chans2plot. This will
% plot everything else
saveName="sample/testplots/power"; % Specify to determine where to save things
plotPowerByCondition(powerdata,f, freqRangeAll, freq_list, color, saveName, trialTypes, conditionOrder, chans2plot, sortedChans)
%% Power Bars split by Condition
% Only things that are modular are frequency, color, and chans2plot. This will
% plot everything else
saveName = "sample/testplots/power2";
plotPowerByTrial(powerdata,f, freqRangeAll, freq_list, color, saveName, trialTypes, conditionOrder, chans2plot, sortedChans)

