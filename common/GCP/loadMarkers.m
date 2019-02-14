function [ markers ] = loadMarkers( folder )
%LOADMARKERS Summary of this function goes here
%   Detailed explanation goes here

    load(fullfile(folder, 'GCPs_in_images.mat'),'markers');

end