function [ longitude, latitude, altitude, IDs, header ] = readGPSfromXLS( xlsFullfile, sheet )
%readGPSfromXLS Summary of this function goes here
%   Detailed explanation goes here

[filePath, fileName, fileExt] = fileparts(xlsFullfile);

%% Read sheet
[~, ~, raw] = xlsread(xlsFullfile, sheet, '', 'basic');

% Remove NaN rows at end
while(isnan(raw{end,1}))
    raw = raw(1:end-1,:);
end

% Handle empty cells (NaN --> '')
raw(cellfun(@(x) all(isnan(x)), raw)) = {''};

% Convert all numbers to strings (to keep things consistent)
raw = cellfun(@(x) num2str(x,15),raw,'UniformOutput',false);

%% Extract header data

version = str2double(raw{1,2});
if (version == 1)
    numHeaders = 8;
    numSpacing = 1;
    firstDataRow = numHeaders + numSpacing + 2;
    
    name = raw{2,2};
    description = raw{3,2};
    location = raw{4,2};
    date = datetime(str2double(raw{5,2}),'ConvertFrom','excel','Format','dd-MMM-yyyy');
    coordinateSystem = raw{6,2};
    refOrUnit = raw{7,2};
    utmZone = raw{8,2};
else
    error(['Unknown version in file: ' fileName '.' fileExt ', sheet: ' sheet])
end

%% Extract data

% X, East
X = cellfun(@(x) strrep(x,',','.'),raw(firstDataRow:end,1),'UniformOutput',false);
X = cellfun(@str2double,X,'UniformOutput',true);
if (iscell(X))
    X = cell2mat(X);
end

% Y, North
Y = cellfun(@(x) strrep(x,',','.'),raw(firstDataRow:end,2),'UniformOutput',false);
Y = cellfun(@str2double,Y,'UniformOutput',true);
if (iscell(Y))
    Y = cell2mat(Y);
end

% Z, Height
Z = cellfun(@(x) strrep(x,',','.'),raw(firstDataRow:end,3),'UniformOutput',false);
Z = cellfun(@str2double,Z,'UniformOutput',true);
if (iscell(Z))
    Z = cell2mat(Z);
end

% IDs
IDs = raw(firstDataRow:end,4);

% Convert coordinates to lontitude-latitude
[longitude, latitude,  altitude, mapStruct, refOrUnit] = xyz2lla(X, Y, Z, coordinateSystem, refOrUnit, utmZone);

% Store header information into struct

[ header ] = setGPSheader(xlsFullfile, ...
                          sheet, ...
                          version, ...
                          name, ...
                          description, ...
                          location, ...
                          date, ...
                          coordinateSystem, ...
                          mapStruct, ...
                          refOrUnit, ...
                          mean(longitude), ...
                          mean(latitude), ...
                          mean(altitude), ...
                          length(X));

end

function [long, lat, alt, utmStruct, refOrUnit] = xyz2lla(x, y, z, coordinateSystem, refOrUnit, utmZone)
% XY2LL Convert coordinates to longitude and latitude
%
%

    if (strcmp(coordinateSystem,'UTM'))
        if (strcmp(refOrUnit,'EGM96'))
            refOrUnit = 'WGS84';
            egm96 = true;
%         elseif (strcmp(refOrUnit,'EGM2008'))
%             refOrUnit = 'WGS84';
%             egm2008 = true;
        end
        utmStruct = defaultm('utm');
        utmStruct.zone = utmZone;
        utmStruct.geoid = referenceEllipsoid(refOrUnit);
        utmStruct = defaultm(utmStruct);
        
        [lat,long,alt] = minvtran(utmStruct, x,y,z);
        geoIdOffset = zeros(size(alt));
        if (strcmp(refOrUnit,'WGS84')) && (~exist('egm96','var'))
            geoIdOffset = geoidheight(lat, long, 'EGM96');
%         elseif (exist('egm2008','var'))
%             geoIdOffset = geoidheight(lat, long, 'EGM2008');
        end
        alt = alt + geoIdOffset;
    elseif (strcmp(coordinateSystem,'LL'))
        utmStruct = [];
        if (strcmp(refOrUnit,'DEG'))
            long = x;
            lat = y;
            alt = z;
        elseif(strcmp(refOrUnit,'RAD'))
            long = x/pi*180;
            lat = y/pi*180;
            alt = z;
        else
            error('Unknown unit for LLE coordinate system. Must be either DEG (decimal degrees) or RAD (radians).');
        end

        longLims = [-180 180];
        latLims = [-90 90];
        if (min(long) < longLims(1)) || (max(long) > longLims(2))
            error(['Longitude outside expected range (' num2str(longLims) ').']);
        end
        if (min(lat) < latLims(1)) || (max(lat) > latLims(2))
            error(['Latitude outside expected range (' num2str(latLims) ').']);
        end
    else
        error(['Unknow coordinate system: ' coordinateSystem]);
    end

end