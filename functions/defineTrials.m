function [trialSets,beh, trialCounts] = defineTrials(beh)
% Defines the trial types from all trial data
%%%% INPUTS %%%%
% beh | beh structure from pre processing scripts

%%%% OUTPUTS %%%%
% trialSets   | structure with trial names as fieldnames and logical vector
%               as entries
% beh         | same behavioral structure with additional meta data
% trialCounts | vector of trial counts per type - all behavioral data

%% Edit here to define all the trials and make them into a structure
% Should be vector of ones and zeros
trialSets=struct();
T1 = randn(1,beh.tn)>0;
T2 = ~T1;

trialSets.name1 = T1;
trialSets.name2 = T2;

%% Edit here to determine condition and save as 'condition' fieldname

if randn>0
    beh.condition ='cond1';
else
    beh.condition = 'cond2';
end

%% No edits needed - gets trial counts
trialNames = fieldnames(trialSets);

for t=1:length(trialNames)
    trialCounts(t) = nansum(trialSets.(trialNames{t}));
end

end
