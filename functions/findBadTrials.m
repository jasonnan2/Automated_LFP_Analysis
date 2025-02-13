function badTrials=findBadTrials(data,method)
% data              | 3D array of size chans x time x trial
% method (optional) | string of outlier detection method in isoutlier() 
if nargin<2
    method='median';
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
            [pxx(c,:,t),f]=pwelch(squeeze(gooddata(c,:,t)),[],[],512,1000);
        catch
            pxx(c,:,t)=nan(1,257);
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
