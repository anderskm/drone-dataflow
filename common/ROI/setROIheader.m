function [ header ] = setROIheader( header, ROIs )
%SETROIHEADER Summary of this function goes here
%   Detailed explanation goes here

header.numROIs = length(ROIs);
Area.min = min([ROIs.area]);
Area.max = max([ROIs.area]);
Area.mean = mean([ROIs.area]);
Area.std = std([ROIs.area]);
Area.unit = ROIs(1).areaUnit;
header.Area = Area;


end

