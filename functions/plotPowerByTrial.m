function plotPowerByTrial(powerdata,f, freqRangeAll, freq_list, color, saveName, trialTypes, conditionOrder, chans2plot, sortedChans)

for freq=1:length(freq_list)
    freqRange=freqRangeAll(freq,:);
    mainTitle=freq_list{freq};
    [~ ,locs]=min(abs(f-freqRange));
    maxChansPerFigure=11;
    aMax = ceil(length(chans2plot)/maxChansPerFigure);
    for a=1:aMax
        figure
        startIdx = (a-1) * maxChansPerFigure + 1; 
        endIdx = min(a * maxChansPerFigure, length(chans2plot)); 
        chans = chans2plot(startIdx:endIdx);     
        combinations=nchoosek(1:length(conditionOrder),2);
        % size rat x region x dose x freqPower x trial type
        for d=1:size(powerdata,3)
            subplot(size(powerdata,3),1,d)
            ylabel(conditionOrder{d})
            hold on
            data = squeeze(nanmean(powerdata(:,chans,d,locs(1):locs(2),:),4)); % get all rat, all dose
            avgdata=squeeze(nanmean(data,1));
            sem=squeeze(nanstd(data,0,1))./sqrt(squeeze(sum(~isnan(data))));
            plotErrBar(avgdata,sem,color)
        
            [ngroups, nbars] = size(avgdata);
            groupwidth = min(0.8, nbars/(nbars + 1.5));
            pvals=[];
            for comb = 1:size(combinations, 1)
                [~,pvals(comb,:)]=ttest(squeeze(data(:,:,combinations(comb,1))),squeeze(data(:,:,combinations(comb,2))));
                
                group1Location = (1:ngroups) - groupwidth/2 + (2*combinations(comb, 1)-1) * groupwidth / (2*nbars);
                group2Location = (1:ngroups) - groupwidth/2 + (2*combinations(comb, 2)-1) * groupwidth / (2*nbars);
                A=[group1Location;group2Location]';
                groupingKey = mat2cell(A, ones(1, size(A, 1)), size(A, 2));
                sigstar(groupingKey,pvals(comb,:))
            end
            xticks([1:length(chans)])
            set(gca,'xticklabel',sortedChans(chans),'fontweight','bold','fontsize',12,'Xticklabelrotation',0)
        end
        sgtitle(mainTitle)
        Lgnd=legend(trialTypes);
        fig=gcf;fig.Position=[1 41 1920 963];
        Lgnd.Position=[0.9101 0.9027 0.0406 0.0846];
        exportgraphics(gcf,saveName+freq_list{freq}+string(a)+".png")
        close all

    end
end

end
