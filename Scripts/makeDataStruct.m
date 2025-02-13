%% Going into all the epoched data section and extracting time series data
clear
cd('F:\LFP_analyzer')
load('sortedChans.mat');sortedChans=replace(sortedChans,' ','');
chans=readtable('sortedChans.xlsx');
mainDir="F:\sampleData\";

%% Make edits here
% set epoching window time range
timeAxis=-3500:1:3500; 
%%% specify window for each timing
%%% MUST BE IN ORDER (ie: TST FIRST, THEN RESP)
timings=struct();
timings.tst = [-1000 1000];
timings.resp = [-3000 3000];

filesection="epochdata2.mat";         % general .mat file name (ie. epochdata2.mat)
                                      % raw epoched data for each session

saveName="sample/testProcessedData/saveName.mat";              % save name for neural data
metaDataFile = "sample/testProcessedData/behDataFile.xlsx";   % name for meta data excel sheet
neuralDataFile = "sample/testProcessedData/neuralBehFile.xlsx"; % name for neural trial counts
studyVarsFilename = 'sample/testProcessedData/parameters.mat'; % name to save some variables for other scripts
%%% condition and trial names, must match those in defineTrials() function
conditionOrder = {'cond1','cond2'};
trialTypes = {'name1','name2'};
%% END OF EDITS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Needs edits if epoching time is different per timing
lockings = fieldnames(timings)';

startTime = [];
endTime = [];

% Get the field names from the timings structure
fields = fieldnames(timings);
% Loop through each field and extract start and end times
for i = 1:numel(fields)
    field = fields{i};
    startTime = [startTime, timings.(field)(1)];
    endTime = [endTime, timings.(field)(2)];
end
% Use logical indexing to find the start and end indices
startIdx = arrayfun(@(x) find(timeAxis == x, 1), startTime);
endIdx = arrayfun(@(x) find(timeAxis == x, 1), endTime);

%% Initializations
mDir=dir(mainDir); mDir(1:2)=[];
ratFolders = mainDir;
ratList = {mDir.name}';
Nrats = length(mDir);
dataStruct=struct();
baseStruct = initializeBase(conditionOrder,trialTypes);
fieldsTop = fieldnames(baseStruct);
subfields = fieldnames(baseStruct.(fieldsTop{1}));
%%% Initializing trial count table
columnNames = { 'condition',  'session', 'N Bad Chans','N Bad Trials',trialTypes{:}};
dataTypes =[{'string', 'string',  'double','double'}, repmat({'double'}, 1, size(trialTypes,2))];

save(studyVarsFilename,'timings','lockings','conditionOrder','trialTypes','sortedChans','chans','ratList')


%% Run the actual program
for r=1:Nrats
    generalCounter=0;
    
    tbl = table('Size', [0, numel(columnNames)], 'VariableNames', columnNames, 'VariableTypes', dataTypes);
    neuralTbl = tbl;
    rat=mDir(r).name;
    if ~isfield(dataStruct,rat)
        dataStruct.(rat)=struct();
    end
    
    %%% Make sure that all session folders are here
    sessionFolders=ratFolders+rat;
    sessionFolders=dir(sessionFolders);sessionFolders(1:2)=[];
    
    count=0;
    sCount=zeros(1,length(conditionOrder));

    for sessionNum=1:length(sessionFolders) % iterating through all sessions per rat
        session=sessionFolders(sessionNum).name; 
        LFPdataFile = fullfile(sessionFolders(sessionNum).folder,session,filesection);
        if exist(LFPdataFile)
            load(LFPdataFile); beh=behLFP.beh; 
            [trialSets,beh, trialCounts] = defineTrials(beh); % trialCounts is all beh data
            condition = beh.condition;
            trialNames = fieldnames(trialSets);
            sumMatrix = zeros(size(trialSets.(trialNames{1})));
            for i = 1:numel(trialNames)
                sumMatrix = sumMatrix + trialSets.(trialNames{i});
            end
            if max(sumMatrix)>1
                error("Check Trial counts for "+rat+"-"+session)
            end
            singledata={};Nmissing=[];
            %%% Stitching different sections together
            for l=1:length(lockings) 
                singledata{l}=behLFP.(lockings{l})(:,startIdx(l):endIdx(l),:);
            end
            data=cat(2,singledata{:});
    
            orderIdx=find(strcmp(conditionOrder,condition)); sCount(orderIdx)=sCount(orderIdx)+1;
            %%% Change here to be one time check
            badChans = all(isnan(data),[2,3]);
            goodchans=setdiff([1:length(sortedChans)],find(badChans));
            chanData = data;
            %%% Initiating the empty vars
            for j = 1:numel(subfields)
                assignin('base', subfields{j}, []);
            end
            %%% initialize condition structure
            if ~isfield(dataStruct.(rat),condition) 
                dataStruct.(rat)=baseStruct;
            end
    
            missingAll=squeeze(all(isnan(chanData),[1,2]));
            missingsome=squeeze(any(isnan(chanData(goodchans,:,:)),[1,2]));
            missingTrials = missingAll==1 | missingsome==1;
    
            
            %%% Trial split
            neuralCounts=[];
            for tri=1:length(trialNames)
                
                trialIdx = trialSets.(trialNames{tri})' & ~missingTrials(:)';
                neuralCounts(tri)=sum(trialIdx);
                trialData=chanData(:,:,trialIdx);
                dataStruct.(rat).(condition).(trialNames{tri}){sCount(orderIdx)}=trialData;
            end
            newRow = {condition, session, sum(badChans),sum(missingTrials)};
            newNeuralRow = [newRow(1:4), num2cell(neuralCounts(:)')];
            newRow = [newRow(1:4), num2cell(trialCounts(:)')];
    
            tbl = [tbl;newRow];
            neuralTbl = [neuralTbl;newNeuralRow];
            clear newRow
        end
    end

%     tbl=natsortrows(tbl, {'session'});
%     neuralTbl=natsortrows(neuralTbl, {'session'});
    writetable(tbl,metaDataFile,'Sheet',rat)
    writetable(neuralTbl, neuralDataFile,'Sheet',rat)
end

save(saveName,'dataStruct','-V7.3')
