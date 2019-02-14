function [ ROIs, header ] = readROIfromXLS( xlsFullfile, sheet )
%READROIFROMXLS Summary of this function goes here
%   Detailed explanation goes here

% Read GPS and header data
[ longitude, latitude, altitude, ROIids, header ] = readGPSfromXLS( xlsFullfile, sheet );

% Convert to ROIstruct
[ ROIs ] = toROIstruct( longitude, latitude, altitude, ROIids );

% Add meta data to header
[ header ] = setROIheader( header, ROIs );

end

