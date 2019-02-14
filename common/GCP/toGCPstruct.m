function [ GCPs ] = toGCPstruct( longitude, latitude, altitude, GCPid )
%TOGCPSTRUCT Summary of this function goes here
%   Detailed explanation goes here

    GCPs = struct([]);
    for u = 1:length(longitude)
        % Store coordinates in struct
        GCPs(u).name = GCPid{u};
        GCPs(u).type = 'point';
        GCPs(u).longitude = longitude(u);
        GCPs(u).latitude = latitude(u);
        GCPs(u).altitude = altitude(u);
    end;

end

