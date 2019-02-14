function [planeParams, inliers, residuals] = fitplane2GCPs(GCPs)
%FIRPLANE2GCP Summary of this function goes here
%   Detailed explanation goes here


XYZ = [[GCPs.UTMEast]; [GCPs.UTMNorth]; [GCPs.UTMHeigt]];

[planeParams, ~, inliers] = ransacfitplane(XYZ, 1, 0);

residuals = heightFromPlane([GCPs.UTMEast], [GCPs.UTMNorth], [GCPs.UTMHeigt], planeParams);

end

