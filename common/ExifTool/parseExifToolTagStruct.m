function [ tagStruct ] = parseExifToolTagStruct( tagStruct, verbose )
%PARSEEXIFTOOLTAGSTRUCT Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 2)
        verbose = false;
    end
    if (verbose)
        disp('Parsing tags in ExifTool tag-struct...');
    end

    tags = fieldnames(tagStruct);
    if (verbose)
        disp('Discovered tag-names:')
        disp(tags)
    end
    
    
    for t = 1:length(tags)
        tag = tags{t};
        
        if (verbose)
            disp(['   Parsing tag: ' tag])
        end

        switch tag
            case 'SourceFile'
                % Do nothing, keep source file name as it is
            case 'GPSAltitude'
                % Handle both single numbers and numbers with unit or other
                % extensions
                % e.g. "131.0", "131.0 m" and "131.0 m above sea level"
                % In all cases above, only 131.0 should be returned. If
                % there is not a space between the number and the unit, it
                % will break and return NaN.
                altitude = cell2mat(cellfun(@(x) str2double(x(1:max(max(isempty(find(x == ' ',1,'first'))*length(x),~isempty(find(x == ' ',1,'first'))*[find(x == ' ',1,'first') 0])))),{tagStruct.GPSAltitude},'UniformOutput',false));
                tagStruct = setFieldInArrayStruct(tagStruct,tag,altitude);
            case 'GPSLatitude'
%                 tagStruct(cellfun(@(x) isempty(x),{tagStruct.GPSLatitude})).GPSLatitude = '"0 deg 0  0.0"" N"';
                DD = parseGPSdmsh2dd({tagStruct.GPSLatitude});
                tagStruct = setFieldInArrayStruct(tagStruct,tag,DD);
            case 'GPSLongitude'
%                 tagStruct(cellfun(@(x) isempty(x),{tagStruct.GPSLongitude})).GPSLongitude = '"0 deg 0  0.0"" E"';
                DD = parseGPSdmsh2dd({tagStruct.GPSLongitude});
                tagStruct = setFieldInArrayStruct(tagStruct,tag,DD);
            case 'GPSXYAccuracy'
%                 tagStruct(cellfun(@(x) isempty(x),{tagStruct.GPSXYAccuracy})).GPSXYAccuracy = '1000';
                GPSXYAccuracy = cell2mat(cellfun(@str2double,{tagStruct.GPSXYAccuracy},'UniformOutput',false));
                tagStruct = setFieldInArrayStruct(tagStruct,tag,GPSXYAccuracy);
            case 'GPSZAccuracy'
%                 tagStruct(cellfun(@(x) isempty(x),{tagStruct.GPSZAccuracy})).GPSZAccuracy = '1000';
                GPSZAccuracy = cell2mat(cellfun(@str2double,{tagStruct.GPSZAccuracy},'UniformOutput',false));
                tagStruct = setFieldInArrayStruct(tagStruct,tag,GPSZAccuracy);
            case 'Yaw'
%                 tagStruct(cellfun(@(x) isempty(x),{tagStruct.Yaw})).Yaw = '0';
                yaw = cell2mat(cellfun(@str2double,{tagStruct.Yaw},'UniformOutput',false));
                tagStruct = setFieldInArrayStruct(tagStruct,tag,yaw);
            case 'Pitch'
%                 tagStruct(cellfun(@(x) isempty(x),{tagStruct.Pitch})).Pitch = '0';
                pitch = cell2mat(cellfun(@str2double,{tagStruct.Pitch},'UniformOutput',false));
                tagStruct = setFieldInArrayStruct(tagStruct,tag,pitch);
            case 'Roll'
%                 tagStruct(cellfun(@(x) isempty(x),{tagStruct.Roll})).Roll = '0';
                roll = cell2mat(cellfun(@str2double,{tagStruct.Roll},'UniformOutput',false));
                tagStruct = setFieldInArrayStruct(tagStruct,tag,roll);
            otherwise
                warning(['Skipping tag "' tag '". Parsing for this tag is not supported yet.']);
        end
    end
    
    if (verbose)
        disp('Parsing all tags completed.');
    end

end

function [struct] = setFieldInArrayStruct(struct, field, values)
    if (iscell(values))
        for i = 1:length(struct)
            struct(i).(field) = values{i};
        end
    else
        for i = 1:length(struct)
            struct(i).(field) = values(i);
        end
    end
end

function DD = parseGPSdmsh2dd(GPS)
    DD = nan(size(GPS));
    for i = 1:length(GPS)
        tokens = regexp(GPS{i}, '"(\d{0,3}) deg (\d{0,2}). (\d{0,2}\.(\d{0,2}))""( \w)"','tokens');
        if (isempty(tokens))
            dd = 0;
        else
            [dd] = dmsh2dd(str2double(tokens{1}{1}),str2double(tokens{1}{2}),str2double(tokens{1}{3}),tokens{1}{4});
        end
        DD(i) = dd;
    end
end

function [dd] = dmsh2dd(d,m,s,h)
% Convert degrees, minuts, seconds and heading format to decimal degrees
    dd = d + (m + (s/60))/60;
    if (strcmp(h,'S') || strcmp(h,'W'))
        dd = -dd;
    end
end