function [ tagStruct ] = readExifToolCSV( csvFilename, verbose )
%READEXIFTOOLCSV Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 2)
        verbose = false;
    end;

    if (verbose)
        disp(['Opening file for reading: ' csvFilename]);
    end
    fid = fopen(csvFilename);
    
    if (verbose)
        disp('Reading and identifying headers');
    end
    headerLine = fgetl(fid);
    headers = strsplit(headerLine,',');
    numHeaders = length(headers);
    if (verbose)
        disp(['   Found ' num2str(numHeaders) ' headers.']);
        disp(headers')
    end
    
    if (verbose)
        disp('Reading data...');
    end
    C = textscan(fid,[repmat('%s',1,numHeaders)],'delimiter',',');
    
    if (verbose)
        disp(['Closing file: ' csvFilename]);
    end
    fclose(fid);
    
    % Convert 
    tagStructCellInput = reshape([headers; C],1,[]);
    tagStruct = struct(tagStructCellInput{:});
end

