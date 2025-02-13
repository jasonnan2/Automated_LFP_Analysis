function [allConnData, sessionCell] = organizeConnectivityData(connectivityData,Ncombos,locs)
    Nrats = size(connectivityData,1);
    allConnData =nan(Nrats,Ncombos);
    for r=1:size(connectivityData,1)
        ratData =[];ratSession =[];
        allSession = connectivityData{r}{1}; % size chan x chan x freq x session
        if ~isempty(allSession)
            avgSessionData = mean(allSession(:,:,locs(1):locs(2),:),[3,4],'omitnan'); % size chan x chan
            sessionBysession  = squeeze(mean(allSession(:,:,locs(1):locs(2),:),[3],'omitnan'));
            for i=1:size(avgSessionData,1)-1
                ratData = cat(2,ratData, avgSessionData(i,i+1:end));
                ratSession = cat(2,ratSession, sessionBysession(i,i+1:end,:));
            end
            allConnData(r,:)=ratData;
        else
            allConnData(r,:)=nan;
        end
        sessionCell{r} = squeeze(ratSession)';
    end
end

