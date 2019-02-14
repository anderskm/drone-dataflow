function [ GCPs, header ] = readGCPfromXLS( xlsFullfile, sheet )
%READGCPFROMXLS Summary of this function goes here
%   Detailed explanation goes here

% Read GPS and header data
[ longitude, latitude, altitude, GCPids, header ] = readGPSfromXLS( xlsFullfile, sheet );

% Convert to ROIstruct
[ GCPs ] = toGCPstruct( longitude, latitude, altitude, GCPids );

% Add meta data to header
[ header ] = setGCPheader( header, GCPs );

end

