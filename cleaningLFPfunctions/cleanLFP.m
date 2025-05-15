function [data] = cleanLFP(rawLFP, threshold, plotChans, fs, freqRange)
% cleanLFP  Cleans broadband noise from LFP recordings using power thresholding.
%
%   data = cleanLFP(rawLFP)
%   data = cleanLFP(rawLFP, threshold)
%   data = cleanLFP(rawLFP, threshold, plotChans)
%   data = cleanLFP(rawLFP, threshold, plotChans, fs)
%   data = cleanLFP(rawLFP, threshold, plotChans, fs, nfft)
%   data = cleanLFP(rawLFP, threshold, plotChans, fs, nfft, freqRange)
%
%   Removes broadband noise artifacts by nulling time bins whose average power
%   within a specified frequency band exceeds a dB threshold.
%
%   ------------------------------------------------------------------------
%   Inputs
%   ------------------------------------------------------------------------
%   rawLFP     : [nChannels × nTimepoints]  Raw LFP matrix.
%   threshold  : (optional) dB threshold for artifact detection (default = 10).
%   plotChans  : (optional) Logical flag to plot raw vs. cleaned traces (default = false).
%   fs         : (optional) Sampling rate in Hz (default = 1000).
%   nfft       : (optional) FFT length for Welch (default = largest power-of-2 ≤ fs/2).
%   freqRange  : (optional) 1×2 vector [fMin fMax] for broadband power (default = [1 250] Hz).
%
%   ------------------------------------------------------------------------
%   Output
%   ------------------------------------------------------------------------
%   data       : Cleaned LFP matrix (same size as rawLFP) with noisy segments set to NaN.
%
%   ------------------------------------------------------------------------
%   Notes
%   ------------------------------------------------------------------------
%   • Power is computed in 30-s bins with 15-s hops (scaled by fs).  
%   • Median DC offset is removed per channel.  
%   • A bin is nulled if *all* channels exceed the dB threshold.  
%

% ------------------------- argument handling -----------------------------
if nargin < 2 || isempty(threshold);  threshold  = 10;      end
if nargin < 3 || isempty(plotChans);  plotChans  = false;   end
if nargin < 4 || isempty(fs);         fs         = 1000;    end
if nargin < 5 || isempty(freqRange);  freqRange  = [1 250]; end
% -------------------------------------------------------------------------

LFPm = rawLFP-nanmedian(rawLFP,2);
% subtract any DC drift.
data=LFPm;
%%
binSize = 30; binSize = round(binSize*fs);
binHop = 15; binHop = round(binHop*fs);
bins = [(1:binHop:(size(rawLFP,2)-binSize+1));(binSize:binHop:size(rawLFP,2))]';
for i = 1:size(bins,1)
    chunk = data(:,bins(i,1):bins(i,2));
    [pxx,f]=pwelch(chunk',[],[],[],fs);
    pxx=pow2db(pxx);
    [~ ,locs]=min(abs(f-freqRange));
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









    
    

