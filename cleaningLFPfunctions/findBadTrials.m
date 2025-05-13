function badTrials=findBadTrials(data,method, fs,nfft)
% findBadTrials  Identifies bad LFP trials using power and variability criteria.
%
%   badTrials = findBadTrials(data)
%   badTrials = findBadTrials(data, method)
%   badTrials = findBadTrials(data, method, fs)
%
%   This function detects poor-quality trials in LFP recordings by evaluating their
%   spectral power and standard deviation. Trials with low or missing power, or those
%   flagged as statistical outliers in variability, are marked as bad.
%
%   Inputs:
%     data    - [nChannels x nTimepoints x nTrials] array of LFP data
%     method  - (Optional) Outlier detection method for isoutlier() (default: 'median')
%     fs      - (Optional) Sampling frequency in Hz (default: 1000 Hz)
%     nfft    - (Optional) Number of FFT points for Welchls method (default: fs/2 rounded to the nearest power of 2)
%
%   Output:
%     badTrials - Indices of trials considered artifacts or outliers
%
%   Methodology:
%     - Trials with missing or sub-zero broadband (0–100 Hz) power are flagged.
%     - Trials with extreme standard deviation across time are iteratively removed.
%     - Trials composed entirely of NaNs are replaced with mean trial activity 
%       temporarily to enable spectral computation.
%
%   Notes:
%     - Uses Welchss method with Fs/2-point FFT rounded to the nearest power of 2.
%     - Suitable for preprocessing steps in LFP denoising pipelines.
if nargin < 2 || isempty(method)
    method = 'median';
end
if nargin < 3 || isempty(fs)
    fs = 1000;
end
if nargin < 4 || isempty(nfft)
    nfft = 2^floor(log2(fs/2));
end


% Step 1: enforce trials >0 db 
goodchans=~all(squeeze(isnan(data)),[2,3]);
gooddata=data(goodchans,:,:);
missingtrials = squeeze(all(isnan(gooddata),[1,2])); % find any trials that are nan
if sum(missingtrials>1)
    gooddata(:,:,missingtrials)=repmat(squeeze(nanmean(gooddata,3)),[1,1,sum(missingtrials)]); % set it to average value to run the rest
    gooddata(isnan(gooddata)) = nanmedian(gooddata,'all');
end

for c=1:size(gooddata,1)
    for t=1:size(gooddata,3)
        try 
            [pxx(c,:,t),f]=pwelch(squeeze(gooddata(c,:,t)),[],[],nfft,fs);
        catch
            pxx(c,:,t)=nan(1,(nfft/2)+1);
        end
    end
end

avgPxx=squeeze(mean(pow2db(pxx),1));
[~ ,locs]=min(abs(f-[0 100]));
if isrow(avgPxx)
    avgPxx=avgPxx';
end
TrialPower = nanmean(avgPxx(locs(1):locs(2),:));
badTrials=[find(TrialPower<0) find(isnan(TrialPower))]; % bad power or missing from first step
cont=1;
longTrial=reshape(data,[],size(data,3)); % collapse all Channels
tSTD = nanstd(longTrial); % trial std from all trials
tSTD(badTrials)=nan; % remove initial bad trials
while cont
    noutliers=length(badTrials);
    newbadTrials = find(isoutlier(tSTD,method));
    badTrials=[badTrials newbadTrials];
    tSTD(badTrials)=nan;
    if length(badTrials)>noutliers % if an outlier was found
        cont=1;
    else
        cont=0;
    end
end

end
