function dataStruct = loadCollatedData(filePaths)
% loads in data from makeDataStruct. can load in single file or multiple
% files

%%% Inputs
% filePaths    | string. If single file, the provide full file with
%                extension. else insert char array with all files to load
    if size(filePaths,1)==1
        if isfile(filePaths)
            load(filePaths)
        else
            error('filePaths is not a File')
        end
    else
        % Initialize an empty struct
        dataStruct = struct();
        % Load each file and merge the fields
        for i = 1:size(filePaths,1)
            tempStruct = load(deblank(filePaths(i,:)));
            fieldNames = fieldnames(tempStruct.dataStruct);
            for j = 1:length(fieldNames)
                dataStruct.(fieldNames{j}) = tempStruct.dataStruct.(fieldNames{j});
            end
        end
    end

end
