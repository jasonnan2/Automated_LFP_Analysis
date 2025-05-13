function [data] = cleanLFP(rawLFP,threshold, plotChans)
% cleanLFP  Cleans broadband noise from LFP recordings using power thresholding.
%
%   data = cleanLFP(rawLFP)
%   data = cleanLFP(rawLFP, threshold)
%   data = cleanLFP(rawLFP, threshold, plotChans)
%
%   This function removes broadband noise artifacts from local field potential (LFP)
%   data by identifying time segments whose power in the 1–250 Hz range exceeds
%   a specified threshold (in decibels).
%
%   Inputs:
%     rawLFP     - [nChannels x nTimepoints] matrix of raw LFP signal
%     threshold  - Scalar power threshold in dB for artifact detection (default: 10 dB)
%     plotChans  - Boolean flag to plot cleaned vs. raw data per channel (default: false)
%
%   Outputs:
%     data       - Cleaned LFP data with broadband noise chunks set to NaN
%
%   Notes:
%     - Power is computed in overlapping 30-second bins with 15-second hops.
%     - Median DC offset is removed from each channel before noise detection.
%     - Chunks with mean power above threshold across all channels are nulled.
% Threshold is dB threshold, default is 10dB. Suggestion to visualize one
% session (plotChans=1) to visually determine threshold (should be clear)
if nargin<3
    plotChans=0;
end
if isempty(threshold)
    threshold = 10;
end

LFPm = rawLFP-nanmedian(rawLFP,2);
% subtract any DC drift.
data=LFPm;
%%
binSize = 30; binSize = round(binSize*1000);
binHop = 15; binHop = round(binHop*1000);
bins = [(1:binHop:(size(rawLFP,2)-binSize+1));(binSize:binHop:size(rawLFP,2))]';
for i = 1:size(bins,1)
    chunk = data(:,bins(i,1):bins(i,2));
    [pxx,f]=pwelch(chunk',[],[],[],1000);
    pxx=pow2db(pxx);
    [~ ,locs]=min(abs(f-[1 250]));
    power(:,i)=mean(pxx(locs(1):locs(2),:),1);
end

%%

% Find chunks with broadband noise
outlier_chunks = all(power > threshold, 1);
% Set corresponding time points in the original time series to NaN
for i = 1:size(bins,1)
    if outlier_chunks(i)
        data(:,bins(i,1):bins(i,2)) = NaN;
    end
end
%%
if plotChans
    figure
    for c=1:size(data,1)
        subplot(4,8,c)
        hold on
        plot(LFPm(c,:),'r')
        plot(data(c,:),'b')

        %legend('removed','kept')
        hold off
    end
end









    
    

