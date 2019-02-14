function [ cameraModels ] = listCameraModels( )
%LISTCAMERAMODELS Summary of this function goes here
%   Detailed explanation goes here

    cameraFolder = fullfile(droneDataflowPath( ), 'MATLAB','common','cameras');
    
    files = dir(fullfile(cameraFolder,'*.mat'));
    
    cameraModels = cellfun(@(x) x(1:end-4),{files.name},'UniformOutput',false);

end

