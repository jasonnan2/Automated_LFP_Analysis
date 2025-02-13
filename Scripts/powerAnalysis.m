%% Calculating power spectrum
% working with collated data in structure format
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

baselineTimings =timings.tst;    % data to use for baseline correction
baselineWindow = [-1000 0];   % what baseline window do you want to use ie: [-1000 0] means -1 sec to 0 
                            % if you don't want baseline correction, leave empty

dataTimings = timings.resp; % data you are interested in. ie resp is response
interestWindow = [0 1000];    % Window of data you are interested in, ie: [0 1000] means 0sec to 1 sec of your epoch of interest

refType='shank'; % reference scheme: choose from  'none','median','shank','closest','ClosestInShank'
saveName ='sample/testProcessedData/powerdata.mat'; % save file
saveSessionName = 'powerdata_session.mat';
%% END OF EDITS
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

%% nFFT parameters - don't change unless you have reason to
nfft=512;
if length(nfft)==1
    fLen=(nfft/2)+1;
else
    fLen=length(nfft);
end

%% Run power analysis
count=0;unrefChans=[];

rats=fieldnames(dataStruct);

Nrats = length(rats);
Nchans = length(sortedChans);
Ntrials = length(trialTypes);
Nconds = length(conditionOrder);
singleSessionPowerData={};
powerdata=nan(Nrats, Nchans,Nconds,fLen,Ntrials);
for r=1:length(rats)
    r
    rat=rats{r};
    conditionOrder=fieldnames(dataStruct.(rat));
    for d=1:length(conditionOrder)
        condition=conditionOrder{d};
        trials=fieldnames(dataStruct.(rat).(condition));
        for tri=1:length(trials)
            allSession = dataStruct.(rat).(condition).(trials{tri});
            for session=1:length(allSession)
                count=count+1;
                [referencedData,unrefChans(count)] = newRef(allSession{session},refType,chans);

                data=referencedData(:,startIdx:endIdx,:); % data of interest
                baseline=referencedData(:,baselineIdx,:); % baselineData

                if size(data,3)>=10 % check if data has more than 10 good trials
                    for c=1:length(sortedChans)
                        if all(squeeze(isnan(data(c,:,:))),'all') % if that channel is all NaN
                            sessiondata(c,:,session)=nan(fLen,1); % average trials
                        else
                            [pxx,f]=pwelch(squeeze(data(c,:,:)),[],[],nfft,1000);
%                             pxx=pow2db(pxx); % if convert to db
                            if ~isempty(baseline)
                                [baselinePxx,f]=pwelch(squeeze(baseline(c,:,:)),[],[],nfft,1000);
%                                 baselinePxx=pow2db(baselinePxx); % if you
%                                 want to convert to db
                                baselineCorr=pxx-baselinePxx;
                                sessiondata(c,:,session)=nanmedian(baselineCorr')'; % average trials
                            else
                                sessiondata(c,:,session)=nanmedian(pxx')'; % average trials
                            end                            
                        end
                    end
                else
                    sessiondata(:,:,session)=nan(length(sortedChans),fLen,1);
                end
            end
            
            if isempty(sessiondata)
                sessiondata=nan(length(sortedChans),fLen,1);
            end
            singleSessionPowerData{r,d,tri}=sessiondata;
            powerdata(r,:,d,:,tri)=nanmedian(sessiondata,3); % average session- size rat x region x condition x freqPower x trial type
            sessiondata=[];
        end
    end
end
save(saveName,'powerdata','f') % powerdata is saved as rats x chan x condition x freq x trial type
save(saveSessionName, 'singleSessionPowerData','f','-v7.3')









        