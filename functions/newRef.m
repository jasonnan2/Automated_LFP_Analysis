function [referencedData,count] = newRef(sessionData,refType,chans)
% newRef  Re-references epoched LFP data using specified spatial strategy.
%
%   [referencedData, count] = newRef(sessionData, refType, chans)
%
%   This function applies re-referencing to LFP signals using various methods
%   (e.g., global median, per-shank median, closest channel). It supports both
%   2D and 3D input data and handles missing/bad channels robustly.
%
%   Inputs:
%     sessionData - [nChannels x nTimepoints x nTrials] or [nChannels x nTimepoints] LFP data
%     refType     - String specifying reference method:
%                     'none'             - No re-referencing
%                     'median'           - Global median reference
%                     'shank'            - Median of channels within same shank
%                     'closest'          - Closest good channel in space
%                     'ClosestInShank'   - Closest good channel within the same shank
%     chans       - Table with channel metadata, must include:
%                     - grouping: shank/group ID
%                     - 3D coordinates in columns 3:end (e.g., x, y, z)
%
%   Outputs:
%     referencedData - Re-referenced data (same size as input sessionData)
%     count          - Number of channels where fallback reference was used (e.g., global median)
%
%   Notes:
%     - Input data is reshaped internally to 2D for processing, then restored to original shape.
%     - Bad channels (all-NaN) are excluded from referencing targets.
%     - For spatial methods, Euclidean distance is used to find nearest neighbors.

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









