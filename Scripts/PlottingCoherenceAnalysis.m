%% PLotting Coherence Analysis

connectivityDataFile = "sample/testProcessedData/ft_connectivity.mat"; % filename for connectivity
studyVarsFilename = 'sample/testProcessedData/parameters.mat'; % study vars to load in
saveName="sample/testplots/"; % where to save things

titleStr = 'extra ID'; % added to title of plot and saveFile name
groupby='trial'; % how you want the bars grouped

load(connectivityDataFile)
% get specific channel order and generates pair labels
c = int32(str2double(ft_connectivity.eleOrder));
conChans = sortedChans(c);
connLabels = nchoosek(conChans,2);
connLabels = strcat(connLabels(:,1),'-',connLabels(:,2));
Ncombos = length(connLabels);

measures = {'wpli'}; % connectivity measures to plot
trials2plot = [1:2];
conditions2plot =[1];
pairs2plot =[1:10]; % based on connLables - inspect to see which pairs to run

freqRangeAll=[0,4]; % frequency range to average
freq_list={'delta'};
color={'k','b','g','r'};

load(studyVarsFilename)

%% 

for m = 1:length(measures)
    measureType=measures{m};
    for freq=1:length(freq_list) % each freq is an excel file
        freqRange=freqRangeAll(freq,:);
        [~ ,locs]=min(abs(ft_connectivity.info.freq'-freqRange));
        allConnData=[];
        for tri=trials2plot
            for con=conditions2plot
                connectivityData = ft_connectivity.(measureType)(:,con,tri);  %cell array size rat x cond x tri
                allConnData(:,con,:,tri) = organizeConnectivityData(connectivityData,Ncombos, locs); % size rat x condition x electrode pairs x tri              
            end
        end
        %%% Plotting function
        plotCoh(allConnData, pairs2plot,groupby, trials2plot, conditions2plot,trialTypes,conditionOrder, ...
            connLabels,  titleStr, measureType,freqName, saveName)
    end
end

%%
selectedallConnData = allConnData(:,:,pairs2plot,:);
plotData = repmat(selectedallConnData,[1,2,1,2]);
%%



%%
function plotCoh(allConnData, pairs2plot,groupby, trials2plot, conditions2plot,trialTypes,conditionOrder,connLabels,titleStr, measureType,freqName, saveName)
% plots coherence into grouped bar charts
%%% INPUTS - just for reference - everything is defined for you in script

% allConnData         | matrix: main data, size rat x condition x pairs x trials
% pairs2plot          | vector: what pairs to plot
% groupby             | 'trials' or 'conditions' - how bars are grouped
% trials2plot         | vector: what trials to plot 
% conditions2plot     | vector: what conditions to plot
% trialTypes          | cell array from parameters
% conditionOrder      | cell array from parameters
% connLables          | pair labels for all pairs
% titleStr            | str: sub title for each plot
% measureType         | str: measure you are plotting
% freqName            | str: freq band you are plotting
% saveName            | str: filename id to save as

mainTitle = strjoin({titleStr  measureType  freqName},' ');
pairsLabel = connLabels(pairs2plot);
trials = trialTypes(trials2plot);
conditions = conditionOrder(conditions2plot);
plotData = allConnData(:,:,pairs2plot,:);
Ntrials = size(plotData,4);
Ncons = size(plotData,2);


if strcmp(groupby, 'condition')
    Nrows = Ntrials;
    legendID = conditions;
    rowLabels = trials;
elseif strcmp(groupby, 'trial')
    Nrows = Ncons;
    legendID =trials;
    rowLabels = conditions;
end

maxChansPerFigure=8;
aMax = ceil(length(pairs2plot)/maxChansPerFigure);
for a=1:aMax
    figure
    hold on

    for r=1:Nrows
        
        subplot(Nrows,1,r)

        startIdx = (a-1) * maxChansPerFigure + 1; 
        endIdx = min(a * maxChansPerFigure, length(pairs2plot)); 
        chans = pairs2plot(startIdx:endIdx);
        
        if strcmp(groupby, 'condition') 
            data =squeeze(plotData(:,:,startIdx:endIdx,r)); % get all rat, all dose
            data=permute(data,[1,3,2]);
        elseif strcmp(groupby, 'trial')
            data =squeeze(plotData(:,r,startIdx:endIdx,:)); % get all rat, all dose
            
        end

        avgdata=squeeze(nanmean(data,1));
        sem=squeeze(nanstd(data,0,1))./sqrt(squeeze(sum(~isnan(data))));
        plotErrBar(avgdata,sem)
        ylabel(rowLabels{r})    
        [ngroups, nbars] = size(avgdata);
        groupwidth = min(0.8, nbars/(nbars + 1.5));
        pvals=[];
        combinations=nchoosek(1:4,2);
        
        for comb = 1:size(combinations, 1)
            try
                [~,pvals(comb,:)]=ttest(squeeze(data(:,:,combinations(comb,1))),squeeze(data(:,:,combinations(comb,2))));
                group1Location = (1:ngroups) - groupwidth/2 + (2*combinations(comb, 1)-1) * groupwidth / (2*nbars);
                group2Location = (1:ngroups) - groupwidth/2 + (2*combinations(comb, 2)-1) * groupwidth / (2*nbars);
                A=[group1Location;group2Location]';
                groupingKey = mat2cell(A, ones(1, size(A, 1)), size(A, 2));
                sigstar(groupingKey,pvals(comb,:))
            end
        end
        xticks([1:ngroups])
        set(gca,'xticklabel',pairsLabel,'fontweight','bold','fontsize',12,'Xticklabelrotation',0)
    end
    sgtitle(mainTitle)
    Lgnd=legend(legendID);
    fig=gcf;fig.Position=[1 41 1920 963];
    Lgnd.Position=[0.9101 0.9027 0.0406 0.0846];
    exportgraphics(gcf,saveName+titleStr+measureType+"_"+freqName+string(a)+".png")
end
end







