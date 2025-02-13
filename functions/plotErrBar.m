 function plotErrBar(data,sem,color_list)
    if nargin<3
        color_list={'k','b','g','r','m','o','c'};
    end
    
    if isrow(data) | iscolumn(data)
        data = vertcat(data,nan(size(data)));
        sem = vertcat(sem,nan(size(sem)));
        xlim([0.5 1.5])
    end
    b=bar(data,'grouped'); hold on % data size N networks x G groups

    for i=1:length(b)
        b(i).FaceColor=color_list{i};
    end

    % Find the number of groups and the number of bars in each group
    [ngroups, nbars] = size(data);
    % Calculate the width for each bar group
    groupwidth = min(0.8, nbars/(nbars + 1.5));
    for i = 1:nbars
        % Calculate center of each bar
        x = (1:ngroups) - groupwidth/2 + (2*i-1) * groupwidth / (2*nbars);
        errorbar(x, data(:,i), sem(:,i), 'k', 'linestyle', 'none');
    end
end