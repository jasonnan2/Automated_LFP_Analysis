function [referencedData,count] = newRef(sessionData,refType,chans)
% Function to rereference epoched data

%%% Inputs
% sessionData  | 32 x time x trials
% refType      | string: 'none','median','shank','closest','ClosestInShank'
% chans        | Chan metadata

count=0;
if ndims(sessionData)>2
    longData = reshape(sessionData,32,[]);
else
    longData = sessionData;
end

coords=table2array(chans(:,3:end));
goodchans=~all(isnan(longData'));
referencedData=nan(size(longData)); % initialize matrix

switch refType
    case 'none'
        referencedData=longData;
        
    case 'median'
        referencedData=longData-nanmedian(longData);
    
    case 'shank'
        for c=find(goodchans)
            shankN = chans(c,:).grouping;
            ChanInShank = chans.grouping==shankN;
            if sum(ChanInShank & goodchans')<2
                referencedData(c,:)=longData(c,:)-nanmedian(longData); % Dont re reference
                count=count+1;
            else
                referencedData(c,:)=longData(c,:)-nanmedian(longData(ChanInShank,:));
            end
        end
    
    case 'closest'
        for c=find(goodchans)
            coord = coords(c,:);
            distance = sqrt(sum((coords-coord)'.^2));
            distance(distance==0)=100; % set itself as far away
            distance(~goodchans)=100; % set bad channels as far away
            [~,refC] = min(distance);
            referencedData(c,:)=longData(c,:)-nanmedian(longData(refC,:));
        end
        
    case 'ClosestInShank'
        for c=find(goodchans)
            shankN = chans(c,:).grouping;
            ChanInShank = chans.grouping==shankN;

            coord = coords(c,:);
            distance = sqrt(sum((coords-coord)'.^2));
            distance(distance==0)=100; % set itself as far away
            distance(~goodchans)=100; % set bad channels as far away
            distance(~ChanInShank)=100; % set channels not in shank as far away
            
            if sum(distance==100)==size(longData,1) % if all other electrodes in shank are bad
                 referencedData(c,:)=longData(c,:); % Dont re reference
            else
                [~,refC] = min(distance);
                referencedData(c,:)=longData(c,:)-nanmedian(longData(refC,:));
            end
        end
end
referencedData = reshape(referencedData,size(sessionData)); % remap ref data to 3D mat
end









