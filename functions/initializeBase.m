function baseStruct = initializeBase(conditionOrder,trialTypes)
% Initialize an empty structure
baseStruct = struct();
% Loop through each condition
for i = 1:length(conditionOrder)
    % Initialize an inner structure for each condition
    innerStruct = struct();
    
    % Loop through each trial type
    for j = 1:length(trialTypes)
        % Assign an empty array to each trial type in the inner structure
        innerStruct.(trialTypes{j}) = [];
    end
    
    % Assign the inner structure to the corresponding condition in the base structure
    baseStruct.(conditionOrder{i}) = innerStruct;
end
end