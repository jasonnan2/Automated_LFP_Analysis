function outliers=findBadChans(data,freqRange,toplot, fs)
% findBadChans  Detects noisy or invalid LFP channels based on spectral outliers.
%
%   outliers = findBadChans(data, freqRange)
%   outliers = findBadChans(data, freqRange, toplot)
%   outliers = findBadChans(data, freqRange, toplot, fs)
%
%   -------------------------------------------------------------------------
%   Inputs
%   -------------------------------------------------------------------------
%   data       : [nChannels × nTimepoints × nTrials]  Epoched LFP data.
%   freqRange  : 1×2 vector [fMin fMax]  Frequency band for analysis (e.g., [1 250]).
%   toplot     : (optional) Logical flag to plot PSDs & highlight outliers (default = false).
%   fs         : (optional) Sampling rate in Hz for Welch PSD (default = 1000).
%
%   -------------------------------------------------------------------------
%   Output
%   -------------------------------------------------------------------------
%   outliers   : Row vector of channel indices flagged as bad.
%
%   -------------------------------------------------------------------------
%   Method
%   -------------------------------------------------------------------------
%   1) Flag channels that are entirely NaN and temporarily fill them with the
%      median spectrum to keep Welch stable.
%   2) Remove trials that are all NaN across channels.
%   3) Flatten remaining trials to a long time-series per channel and compute
%      Welch PSD (pwelch) with the user-supplied (or default) sampling rate.
%   4) Restrict PSD to freqRange and iteratively mark a channel as bad if
%      >30 % of its frequency bins are outliers (isoutlier) relative to the
%      population median. Converge when no new outliers are found.
%   5) Optionally plot PSDs, coloring bad channels red.
%
% -------------------------------------------------------------------------

% ------------------ argument handling ------------------------------------
if nargin <2  || isempty(freqRange), freqRange = [1 250];
if nargin < 3 || isempty(toplot), toplot = false; end
if nargin < 4 || isempty(fs),     fs     = 1000;  end
% -------------------------------------------------------------------------

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

[pxx,f]=pwelch(long',[],[],[],fs);
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
    plot(f,movmean(pxx,fs))
    colororder(color)
    xlim(freqRange) % for plotting
end
outliers=[badChans' outliers];
end