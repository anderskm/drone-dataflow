function [ outputCsvFilename ] = exiftoolExtractTagsToCSV(tags, imageFolder, imageFile, outputCsvFilename, verbose )
%EXIFTOOLEXTRACTTAGSTOCSV Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 5)
        verbose = false;
    end;

    % Save current directory to return to it later
    thisDir = pwd;
    
    % Change dir to image folder
    cd(imageFolder);
    
    % Capture any errors, so that the script can return to the original
    % directory before rethrowing the error
    try
        % Convert tags to a tag string to ExifTool
        tagsStr = tags2str(tags);
        
        % Convert files to a files string to ExifTool
%         filesStr = files2str(files);
%         filesStr = ['"' fullfile(imageFolder,['*.' imageFile]) '"'];
%         filesStr = ['"' ['*.' imageFile] '"'];
        filesStr = ['"' imageFile '"'];
        
        % Call exiftool to store in csv-file
        [status, cmdout] = exiftool(['-csv > "' outputCsvFilename '" -TAG ' tagsStr filesStr], verbose);
    
        if (status ~= 0)
            disp('Start of ExifTool command line output:');
            disp(' ');
            disp(cmdout);
            disp(' ');
            disp('End of ExifTool command line output.');
            error(['ExifTool exited with error code ' num2str(status) '. For debugging, see ExifTool command line outputs above.']);
        end
    catch ex
        % Change back to previously directory
        cd(thisDir);
        rethrow(ex)
    end
    
    % Change back to previously directory
    cd(thisDir);

end

function tagsStr = tags2str(tags)
    if (iscell(tags))
        tagsStr = cell2mat(cellfun(@tag2str, tags,'UniformOutput',false));
    elseif (ischar(tags))
        tagsStr = tag2str(tags);
    else
        error('Unknown tags format. Tags must be either a char array or a cell of char arrays.');
    end
end

function tagStr = tag2str(tag)
    tagStr = ['-' tag ' '];
end

function filesStr = files2str(files)
    if (iscell(files))
        filesStr = cell2mat(cellfun(@file2str, files,'UniformOutput',false));
    elseif (ischar(files))
        filesStr = file2str(files);
    else
        error('Unknown files format. Files must be either a char array or a cell of char arrays.');
    end
end

function fileStr = file2str(file)
    fileStr = ['"' file '" '];
end