%% Saving data to excel
clear
addpath('Functions')
cd('F:\LFP_analyzer')
studyVarsFilename = ['sample/testProcessedData/parameters.mat']; % study vars to load in
load(studyVarsFilename)
%% Define general parameters
saveFolder = "sample/testExcel/";       % main folder to save to
saveID = "";                     % appeneded to each file that is saved
freqRangeAll=[0,4];              % frequency range to average
freq_list={'delta'};             % frequency names in cell array
trials2save = [1,2];             % Trial types to save, numerical array
conditions2save =[1,2];          % Conditions to save, numerical array

%%% Things for power
powerDataFile = "sample/testProcessedData/powerdata.mat"; % filename for power data
powerSessionDataFile = "sample/testProcessedData/powerdata_session.mat";
metaDataExcel = "sample/testProcessedData/behDataFile.xlsx";
chans2save = [6,7,8,9,10];       % Channels to export - power only, numerical array

%%% Things for connectivity
connectivityDataFile = "sample/testProcessedData/ft_connectivity.mat"; % filename for connectivity
measure = {'wpli'};  % connectivity measures to save

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist(saveFolder)
    mkdir(saveFolder)
end

%% Saving averaged power data

load(powerDataFile) % load power data
for freq=1:length(freq_list) % each freq is an excel file
    freqRange=freqRangeAll(freq,:);
    [~ ,locs]=min(abs(f-freqRange));
    
    for tri=trials2save
        for con=conditions2save
            data = squeeze(nanmean(powerdata(:,chans2save,con,locs(1):locs(2),tri),4)); % data is format rat x chan
            tbl=[table(ratList,'VariableNames',{'rats'}) array2table(data, "VariableNames",sortedChans(chans2save))];
            writetable(tbl,saveFolder+saveID+"_power_"+freq_list{freq}+".xlsx",'Sheet',[conditionOrder{con} '_' trialTypes{tri}])
        end
    end
end

%% Saving session data
saveID = '';
load(powerSessionDataFile)

for freq=1:length(freq_list) % each freq is an excel file
    freqRange=freqRangeAll(freq,:);
    [~ ,locs]=min(abs(f-freqRange));
    
    for tri=trials2save
        for con=conditions2save
            tbl = table();
            for r=1:length(ratList)
                ratData = singleSessionPowerData{r,con,tri};
                Nsessions = size(ratData,3);
                data = squeeze(nanmean(ratData(chans2save,locs(1):locs(2),:),2))';

                metaData = readtable(metaDataExcel,'sheet',ratList{r});
                conditionStamps = ismember(metaData.condition,conditionOrder{con});
                if sum(conditionStamps)>0 & ~isnan(mean(data,[1,2,3],'omitnan'))
                    ratTbl = [table(repmat(ratList(r), Nsessions,1), 'VariableNames',{'rats'}) ...
                        metaData(conditionStamps,1:2) array2table(data, "VariableNames",sortedChans(chans2save))];
                    tbl=[tbl; ratTbl];
                end
            end
            writetable(tbl,saveFolder+saveID+"_powerSession_"+freq_list{freq}+".xlsx",'Sheet',[conditionOrder{con} '_' trialTypes{tri}])
        end
    end
end

%% Saving averaged Connectivity data - MUST RUN POWER DATA FIRST
load(connectivityDataFile)
% get specific channel order and generates pair labels
c = int32(str2double(ft_connectivity.eleOrder));
conChans = sortedChans(c);
connLabels = nchoosek(conChans,2);
connLabels = strcat(connLabels(:,1),'-',connLabels(:,2));
Ncombos = length(connLabels);
for m = 1:length(measure)
    measureType=measure{m};
    for freq=1:length(freq_list) % each freq is an excel file
        freqRange=freqRangeAll(freq,:);
        [~ ,locs]=min(abs(ft_connectivity.info.freq'-freqRange));
        for tri=trials2save
            for con=conditions2save
                connectivityData = ft_connectivity.(measureType)(:,con,tri);  %cell array size rat x cond x tri
                [allConnData, sessionCell] = organizeConnectivityData(connectivityData,Ncombos, locs);
                %%% Saving session avg data
                tbl=[table(ratList,'VariableNames',{'rats'}) array2table(allConnData,"VariableNames",connLabels)];
                writetable(tbl,saveFolder+saveID+measureType+"_"+freq_list{freq}+".xlsx", ...
                    'Sheet',[conditionOrder{con} '_' trialTypes{tri}])

                %%% Saving session by session data
                sessionHeaders={};
                for r=1:length(ratList)
                    metaData = readtable(metaDataExcel,'sheet',ratList{r});
                    conditionStamps = ismember(metaData.condition,conditionOrder{con});
                    Nsessions = sum(conditionStamps);
                    if Nsessions>0
                        sessionHeaders =[sessionHeaders; repmat(ratList(r), Nsessions,1) metaData{conditionStamps,1:2}];
                    end
                end
                concatenatedMatrix = cell2mat(cellfun(@(x) x, sessionCell, 'UniformOutput', false)');
                if iscolumn(concatenatedMatrix)
                    concatenatedMatrix=concatenatedMatrix';
                end
                if ~all(isnan(concatenatedMatrix))
                    sessionTbl = [cell2table(sessionHeaders, 'variableNames',{'rat','condition','date'}) ...
                        array2table(concatenatedMatrix,"VariableNames",connLabels)];
                    writetable(sessionTbl,saveFolder+saveID+measureType+"_session_"+freq_list{freq}+".xlsx", ...
                        'Sheet',[conditionOrder{con} '_' trialTypes{tri}])
                end

                allConnData=[]; concatenatedMatrix=[];

            end
        end
    end
end







