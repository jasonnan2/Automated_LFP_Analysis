%% Coherence Analysis
clear
addpath('Functions')
cd('F:\LFP_analyzer')
studyVarsFilename = 'sample/testProcessedData/parameters.mat'; % study vars to load in
load(studyVarsFilename)

% working with collated data in structure format
clear
addpath('Functions')
addpath('fieldtrip_toolbox')
ft_defaults
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
chans2run=[25,20,1,29,17];  % Chans to run 
measures2Run = {'wpli'};   % specify which measures you want to run, wpli, imcoh, coh, granger
baselineTimings =timings.tst;    % data to use for baseline correction

dataTimings = timings.resp; % data you are interested in. ie resp is response
interestWindow = [0 1000];    % Window of data you are interested in, ie: [0 1000] means 0sec to 1 sec of your epoch of interest

refType='shank'; % reference scheme: choose from  'none','median','shank','closest','ClosestInShank'
saveName ='sample/testProcessedData/ft_connectivity.mat'; % save file

%% END OF EDITS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Initializing timings and index
if length(lockings)>1
    trialOffset = baselineTimings(2)-baselineTimings(1) +1; 
else 
    trialOffset=0;
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
%%
ft_connectivity=struct();
rats=fieldnames(dataStruct);
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
                if size(allSession{session},3)>=10 

                    [referencedData] = newRef(allSession{session},refType,chans);
                    allChanData=referencedData(:,startIdx:endIdx,:);
                    LFPdata=allChanData(chans2run,:,:);
                    freqDecomp = ft_formattedCPSD(LFPdata,chans2run);

                    %%% Calcualting connectivity
                    % Coherence magnitude
                    if ismember('coh',measures2Run)
                        cfg           = [];
                        cfg.method    = 'coh';
                        coh           = ft_connectivityanalysis(cfg, freqDecomp);
                        cohSession(:,:,:,session) = coh.cohspctrm;
                    end
                    
                    % Imaginary coherence
                    if ismember('imcoh',measures2Run)
                        cfg           = [];
                        cfg.method    = 'coh';
                        cfg.complex   = 'imag';
                        imCoh           = ft_connectivityanalysis(cfg, freqDecomp);
                        imcohSession(:,:,:,session) = imCoh.cohspctrm;
                    end
%                     
                    % Granger Causality - ### SET ZEROS TO NAN
                    if ismember('granger',measures2Run)
                        cfg           = [];
                        cfg.method    = 'granger';
                        granger = ft_connectivityanalysis(cfg, freqDecomp);
                        granger.grangerspctrm(granger.grangerspctrm==0)=nan;
                        grangerSession(:,:,:,session) = granger.grangerspctrm;
                    end
                        
                    % Weighted Phase Lag Index
                    if ismember('wpli',measures2Run)
                        cfg = [];
                        cfg.method = 'wpli_debiased';
                        wpli = ft_connectivityanalysis(cfg, freqDecomp);
                        wpliSession(:,:,:,session) = wpli.wpli_debiasedspctrm;
                    end

                else
                    if ismember('coh',measures2Run)
                        cohSession(:,:,:,session) = nan(length(chans2run),length(chans2run),length(freqDecomp.freq));
                    end
                    if ismember('imcoh',measures2Run)
                        imcohSession(:,:,:,session) = nan(length(chans2run),length(chans2run),length(freqDecomp.freq));
                    end
                    if ismember('granger',measures2Run)
                        grangerSession(:,:,:,session) = nan(length(chans2run),length(chans2run),length(freqDecomp.freq));
                    end
                    if ismember('wpli',measures2Run)
                        wpliSession(:,:,:,session) = nan(length(chans2run),length(chans2run),length(freqDecomp.freq));
                    end

                end
            end
            if ismember('coh',measures2Run)
                ft_connectivity.coh{r,d,tri} = {cohSession};
            end
            if ismember('imcoh',measures2Run)
                ft_connectivity.imCoh{r,d,tri} ={imcohSession} ;
            end
            if ismember('granger',measures2Run)
                ft_connectivity.granger{r,d,tri} = {grangerSession};
            end
            if ismember('wpli',measures2Run)
                ft_connectivity.wpli{r,d,tri}= {wpliSession};
            end
            cohSession=[];imcohSession=[];grangerSession=[];wpliSession=[];
        end
    end
end
ft_connectivity.info.freq = freqDecomp.freq;
ft_connectivity.eleOrder = freqDecomp.label;
% save(saveName,'ft_connectivity')

%% Fieldtrip cpsd decomp
function freqDecomp = ft_formattedCPSD(LFPdata,c)
sr=1000;

data = [];
data.ntrials = size(LFPdata,3);
data.nsignal = size(LFPdata,1); % electrodes
data.fsample = sr; % check
data.triallength = size(LFPdata,2);
times=[0:size(LFPdata,2)-1]/sr;


for k = 1:size(LFPdata,3)
    data.trial{1,k} = double(LFPdata(:,:,k));
    data.time{1,k} = double(times);
end

vcnt=0;
for v = 1:size(LFPdata,1)
    vcnt = vcnt+1;
    data.label{vcnt,1}=strcat(num2str(c(v)));
end

% Non parametric computation of the
% cross-spectral density matrix
cfg           = [];
cfg.method    = 'mtmfft';
cfg.taper     = 'dpss';
cfg.output    = 'fourier';
cfg.tapsmofrq = 2;
cfg.pad = 'nextpow2';
try
    freqDecomp          = ft_freqanalysis(cfg, data);
catch ME
    if(strcmp(ME,"data = ft_checkdata(data, ...'datatype', {'raw', 'raw+comp', 'mvar'},'feedback', cfg.feedback, 'hassampleinfo', 'yes');"))
%         continue;
    end
end
end


        






