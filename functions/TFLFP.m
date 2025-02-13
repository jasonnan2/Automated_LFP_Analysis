function  [ERSP_Pxx, Phase_Pxx, LFPtimes, freq, TFBaseline] = TFLFP(data, times,baseline, cutoffFreq)
%% Modified from timeFrequencyDecomposition from EEGLAB
%for the actual LFP aligned to the event of interest
LFP.data=data;
LFP.times=times;
LFP.nbchan=size(data,1);
LFP.trials=size(data,3);
LFP.srate=1000;

LFPtimes = LFP.times;
indrm = LFP.times<LFP.times(1)*1 | LFP.times>LFP.times(end)*1;
LFPtimes(indrm) = [];


for ch=1:LFP.nbchan
    disp(ch)
    data = double(squeeze(LFP.data(ch,:,:)));
    for t=1:LFP.trials
        [wt,freq] = cwt(data(:,t), 'amor', LFP.srate);
        if (t==1 && ch==1)
            ERSP_Pxx = zeros([LFP.nbchan, length(freq), length(LFPtimes), LFP.trials]);
            Phase_Pxx = zeros([LFP.nbchan, length(freq), length(LFPtimes), LFP.trials]);
            [~,sorting] = sort(freq);
        end
        ERSP_Pxx(ch, :,:,t) = abs(wt(sorting,~indrm)).^2;
        Phase_Pxx(ch, :,:,t) = unwrap(angle(wt(sorting,~indrm)));
    end
end
freq = freq(sorting);
%ERSP_Pxx(:,freq<2,:,:) = [];
%Phase_Pxx(:,freq<2,:,:) = [];
%freq(freq<2) = [];


%% optimizing the length
%[#sources, #freq, #trials, #times]
ERSP_Pxx = permute(ERSP_Pxx,[1 2 4 3]);
Phase_Pxx = permute(Phase_Pxx,[1 2 4 3]);
%Optimizing the number of frequencies and timepoints
%for freq 
tmp = bsxfun(@(x,y) abs(x-y), [cutoffFreq(1):cutoffFreq(2)], freq);
[~, freqidx] = min(tmp,[],1);
freqidx = unique(freqidx);
freq = freq(freqidx);
%times: average every 6 timepoints (in case of srate 250Hz) to smooth to about 25 ms. 
smoothwindow = 1; %round(25/(1000/LFP.srate));
LFPtimes = mean(reshape(LFPtimes(1:end-rem(end,smoothwindow)),smoothwindow,[]),1);
%reflect the modified freq and time axis in the ERSP and Phase information
%get time dimension to be the last
%[#sources, #freq, #times, #trials]
ERSP_Pxx = permute(squeeze(mean(reshape(ERSP_Pxx(:,freqidx,:,1:end-rem(end,smoothwindow)), LFP.nbchan, length(freq), LFP.trials, smoothwindow, []),4)),[1 2 4 3]);
Phase_Pxx = permute(squeeze(mean(reshape(Phase_Pxx(:,freqidx,:,1:end-rem(end,smoothwindow)), LFP.nbchan, length(freq), LFP.trials, smoothwindow, []),4)),[1 2 4 3]);

if ~isempty(baseline)
    %find ERSP for the baseline LFPmatrix
    if numel(baseline) == 2
        baseline = LFPtimes>baseline(1) & LFPtimes<=baseline(2);
        %     baseline(indrm) = [];
        TFBaseline = mean(mean(ERSP_Pxx(:,:,baseline,:),3),4);
    else
        TFBaseline = baseline;
    end
    ERSP_Pxx = bsxfun(@minus,ERSP_Pxx, TFBaseline);
else
    TFBaseline = [];
%     TFBaseline = mean(mean(ERSP_Pxx,3),4); %get a grand average across time axis
%     ERSP_Pxx = bsxfun(@minus,ERSP_Pxx, TFBaseline);
end

end

