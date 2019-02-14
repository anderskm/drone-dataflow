function [outputCsvFilename] = exiftoolExtractPosAndOrientationToCSV( imageFolder, imgExt, outputCsvFilename, verbose )
%EXIFTOOLEXTRACTPOSANDORIENTATION Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 4)
        verbose = false;
    end;

    % Save current directory to return to it later
    thisDir = pwd;
    % Change dir to image folder
    cd(imageFolder);
    try
        % Call exiftool to store in csv-file
        [status, cmdout] = exiftool(['-csv > "' outputCsvFilename '" -TAG -Yaw -Pitch -Roll "' ['*.',imgExt] '"'], verbose);
    
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

