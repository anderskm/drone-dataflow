function [ status, cmdout ] = exiftool( commandString, verbose )
%EXIFTOOL Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 2)
        verbose = false;
    end;

    if (verbose)
        disp('Checking for previously set ExifTool path.');
    end
    % Check if path for ExifTool has been set previously, otherwise prompt
    % user to locate exiftool.exe
    % If the path has been set previously, it should will be stored in
    % exitfool.mat in the same folder as this script is located.
    [mFilePath, ~, ~] = fileparts(mfilename('fullpath'));
    if (exist(fullfile(mFilePath, 'exiftool.mat'),'file'))
        load(fullfile(mFilePath, 'exiftool.mat'),'exifToolPath');
        if (~exist('exifToolPath','var'))
            if (verbose)
                disp('Previously stored exifToolPath not found. Prompting user to locate path.');
            end
            exifToolPath = locateAndSaveExifToolPath(mFilePath);
        else
            if (~exist(exifToolPath,'file'))
                if (verbose)
                    disp('File in previously stored ExifTool Path does not exist. Prompting user to locate path.');
                end
                exifToolPath = locateAndSaveExifToolPath(mFilePath);
            else
                if (verbose)
                    disp('ExifTool path located and file exists. No need for user interaction.');
                end
            end;
        end
    else
        if (verbose)
            disp('Previously stored "ExifTool path"-file not found. Prompting user to locate path.');
        end
        exifToolPath = locateAndSaveExifToolPath(mFilePath);
    end
    
    % Prepare string with exif tool path
    cmdStr = ['"' exifToolPath '" ' commandString];
    
    if (verbose)
        disp('Calling exiftool:');
        disp(['   ' cmdStr]);
    end
        
    % Call ExifTool
    [status, cmdout] = system(cmdStr);
    
    if (verbose)
        disp('ExifTool call finished:');
        disp(['   Exit code: ' num2str(status)])
        disp(['   Output   : '])
        disp([cmdout])
    end;

end

function exifToolPath = locateAndSaveExifToolPath(mFilePath)
    [FileName,PathName,~] = uigetfile('exiftool*.exe','Locate ExifTool.exe');
    if (PathName == 0)
        error('User cancelled ExifTool path location.')
    end
    exifToolPath = fullfile(PathName, FileName);
    
    save(fullfile(mFilePath, 'exiftool.mat'),'exifToolPath')
    
end