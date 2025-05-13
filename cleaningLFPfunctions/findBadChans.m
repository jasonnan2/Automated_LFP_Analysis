function outliers=findBadChans(data,freqRange,toplot)
% findBadChans  Detects noisy or invalid LFP channels based on spectral outliers.
%
%   outliers = findBadChans(data, freqRange)
%   outliers = findBadChans(data, freqRange, toplot)
%
%   This function identifies bad LFP channels based on deviations in power spectrum
%   within a specified frequency range. Channels with excessive spectral power are 
%   marked as outliers, as are channels that contain only NaNs. It also handles
%   bad trials and optionally plots spectral diagnostics.
%
%   Inputs:
%     data       - [nChannels x nTimepoints x nTrials] array of LFP data
%     freqRange  - [fMin fMax] vector specifying frequency band for outlier detection (e.g., [1 250])
%     toplot     - (Optional) Boolean flag to visualize power spectra and detected outliers (default: false)
%
%   Output:
%     outliers   - Indices of bad channels (includes NaN-only channels and spectral outliers)
%
%   Notes:
%     - Channels containing only NaNs across all time/trials are flagged and temporarily replaced
%       for spectral estimation.
%     - Trials containing only NaNs across all channels are removed prior to analysis.
%     - Iterative outlier removal is based on median filtering and per-channel spectral z-scores.
if nargin<3
    toplot=0;
end
badChans=[]; outliers=[]; cont=1; badTrials=[];
%% find channels that are ALL nan
badChans=find(sum(sum(isnan(data),2),3)>=size(data,2)*size(data,3)); 
if ~isempty(badChans)
    a=squeeze(nanmean(data,1));
    data(badChans,:,:)=permute(repmat(a,[1,1,length(badChans)]),[3,1,2]); % set bad chan to avg of other chans so pwelch can run
end
%% finding bad trials (across ALL electrodes)
badTrials=find(sum(sum(isnan(data),1),2)==size(data,1)*size(data,2)); 
data(:,:,badTrials)=[];

%% Power decomposition for outlier detection
long=reshape(data,size(data,1),[]); % flatten trials
long(:,isnan(long(1,:)))=[];

[pxx,f]=pwelch(long',[],[],[],1000);
pxx=pow2db(pxx); % convert to dB

[~ ,l1]=min(abs(f-freqRange(1)));
[~ ,l2]=min(abs(f-freqRange(2))); % only look up to 250 Hz for Nyquist
if ~isempty(badChans)
    holder=nanmedian(pxx,2);
    pxx(:,badChans)= repmat(holder,[1,length(badChans)]); % set bad channel to median so it doesnt get rejected
end

avgP=mean(pxx(l1:l2,:));
shortPxx=pxx(l1:l2,:);
% iteratively remove outliers with median 
while cont
    pctOutlier = sum(isoutlier(shortPxx,2))/size(shortPxx,1);
    noutliers=length(outliers); % find number of outliers before this iteration
    outliers=[outliers find(pctOutlier>0.3)];
    shortPxx(:,outliers)=nan;
    if length(outliers)>noutliers % if an outlier was found
        cont=1;
    else
        cont=0;
    end
end

%out=find(isoutlier(avgP,'g'))
if toplot
    color=repmat({'b'},32,1);
    color(outliers)={'r'};
    plot(f,movmean(pxx,1000))
    colororder(color)
    xlim([0 250]) % for plotting
end
outliers=[badChans' outliers];
end