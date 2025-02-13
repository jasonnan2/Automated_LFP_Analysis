%% Time frequency decomposition
clear
addpath('Functions')
cd('F:\LFP_analyzer')
studyVarsFilename = 'sample/testProcessedData/parameters.mat'; % study vars to load in
load(studyVarsFilename)
mainDir="F:\sampleData\";
%% Loading in data

%%% If loading in single file, use this
filePaths  = 'sample/testProcessedData/saveName.mat';
%%% If you have have multiple smaller files, use this to combine them all
filePaths = pickfiles('.','saveName'); % this finds all files with this id load in
dataStruct = loadCollatedData(filePaths);

%% Defining timings for baseline correction

chans2run=[1:2]; % what channels to run TF on -need at least 2
baselineTimings =timings.tst;    % data to use for baseline correction
baselineWindow = [-1000 0];   % what baseline window do you want to use ie: [-1000 0] means -1 sec to 0 
                            % if you don't want baseline correction, leave empty

dataTimings = timings.resp; % data you are interested in. ie resp is response
interestWindow = [0 1000];    % Window of data you are interested in, ie: [0 1000] means 0sec to 1 sec of your epoch of interest
stitchedTime = [baselineTimings(1):baselineTimings(2) dataTimings(1):dataTimings(2)];
refType='shank'; % reference scheme: choose from  'none','median','shank','closest','ClosestInShank'
saveName =''; % save file
saveSessionName = '';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initializing timings and index
if length(lockings)>1
    trialOffset = baselineTimings(2)-baselineTimings(1) +1; 
else 
    trialOffset=0;
end

%%% getting baseline Index
if ~isempty(baselineWindow)
    baselineStartIdx = floor(baselineWindow(1) - baselineTimings(1) + 1);
    baselineEndIdx = floor(baselineWindow(2) - baselineTimings(1) + 1);
    baselineIdx = baselineStartIdx:baselineEndIdx;
    if baselineStartIdx<0 || baselineEndIdx>baselineTimings(2)-baselineTimings(1) +1
        error('Baseline Time is outside the extracted timings')
    end
end
%%% Getting Index of data of interest
startIdx=interestWindow(1)-dataTimings(1)+trialOffset; % set Index for start of reward period of interest 
endIdx=interestWindow(2)-dataTimings(1)+trialOffset; % 4000 is +1 sec reward locked Reward offse is 2000 for -1 1 trial locked data 

%% Run single rat

ratID='R402'; % string
condition='cond1'; % string
trial='name1'; % string
allSession = dataStruct.(ratID).(condition).(trial);
ERSPdata = runTF(allSession,refType, chans, chans2run,baselineIdx);

%% Run multiple rats and average

condition='cond1'; % string
trial='name1'; % string

ERSPdata =[];
for r=1:length(ratList)
    allSession = dataStruct.(ratList{r}).(condition).(trial);
    ratERSP = runTF(allSession,refType, chans, chans2run,baselineIdx);
    ERSPdata = cat(4, ERSPdata,ratERSP);
end
ERSPdata = nanmean(ERSPdata,4);
%% Plotting
% Edit here - be careful, these are index from stitched data. 
baseline2plot = baselineStartIdx:baselineEndIdx; % vector of baseline indices you want to plot
trial2plot = startIdx+1:endIdx+1; % vector of baseline indices you want to plot

plotIdx = [baseline2plot trial2plot];
plotTimes=stitchedTime(plotIdx);

labels2run = sortedChans(chans2run);
[Nrows, Ncols] = optimalGrid(length(labels2run));
count=0;

diffVec = diff(plotTimes);
xticksIdx = sort([1,  find(baseline2plot==0), find(trial2plot==0)+length(baseline2plot), length(plotTimes)]);
breakIdx = length(baseline2plot);
close all
for c=1:length(labels2run)
    count=count+1;
    plotdata = squeeze(ERSPdata(c,:,plotIdx));
    subplot(Nrows, Ncols, count)
    imagesc([],[],plotdata)
    hold on 
    for b = 1:length(breakIdx) 
        xline(breakIdx(b),'--k','LineWidth',1.5); 
        text(breakIdx(b), -0.5, num2str(stitchedTime(breakIdx(b))), 'HorizontalAlignment', 'right');
        text(breakIdx(b), 0, num2str(stitchedTime(breakIdx(b)+1)), 'HorizontalAlignment', 'left');

        text(breakIdx(b)-50, 40, 'Baseline','HorizontalAlignment','right','rotation',0,'fontweight','bold','fontsize',12)  
        text(breakIdx(b)+50, 40, 'Trial data','HorizontalAlignment','left','rotation',0,'fontweight','bold','fontsize',12) 
    end
    hold off
    title(labels2run(c))
    set(gca,'YTick',[1:4:11 13:4:43],'YTicklabel',(round(freq([1:4:11 13:4:43]))))

    set(gca,'Ydir','normal')
    cb=colorbar;
    ylabel('Frequency','fontweight','bold')
    ylabel(cb,'Power','FontSize',8,'Rotation',270,'fontweight','bold');
    cb.Label.Position=[2.7733 40.7207 0];
    cb.Label.VerticalAlignment = 'middle';
    xlabel('Time (mS)','fontweight','bold')
    set(gca, 'Xtick',xticksIdx, 'XTicklabel',plotTimes(xticksIdx))
end

%%
function [nRows, nCols] = optimalGrid(numPlots)
    % Start with the smallest number of rows
    nRows = floor(sqrt(numPlots));
    % Calculate the number of columns
    nCols = ceil(numPlots / nRows);
    
    % Adjust the number of rows and columns if necessary
    while (nRows * nCols < numPlots)
        nRows = nRows + 1;
        nCols = ceil(numPlots / nRows);
    end
end

function ERSPdata = runTF(allSession,refType, chans, chans2run,baselineIdx)

    avgERSP=[];
    for session=1:length(allSession)
        [referencedData] = newRef(allSession{session},refType,chans);
        if size(referencedData,3)>10 & ~isempty(referencedData)
            [ERSP_Pxx, ~, LFPtimes, freq, ~] =TFLFP(referencedData(chans2run,:,:),[1:size(referencedData,2)],[],[0 100]);
            avgSessionData = nanmean(ERSP_Pxx,4);
            if ~isempty(baselineIdx)
                baselineSection = nanmean(avgSessionData(:,:,baselineIdx),3);
                avgSessionData = avgSessionData - baselineSection;
            end
            avgERSP = cat(4,avgERSP,avgSessionData);
        end
    end
    ERSPdata = nanmean(avgERSP,4);

end
