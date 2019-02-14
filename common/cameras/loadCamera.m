function [ camera ] = loadCamera( cameraModel)
%LOADCAMERA Summary of this function goes here
%   Detailed explanation goes here


cameraModels = listCameraModels( );

if (nargin < 1)
    cameraModel = [];
end

if (isempty(cameraModel))

    [selectionIdx,ok] = listdlg('ListString', cameraModels, ...
                                'SelectionMode','single', ...
                                'Name','Select camera model', ...
                                'PromptString','Select a camera model:', ...
                                'OKString','OK',...
                                'CancelString','Cancel');
    if (strcmp(ok,'OK') || (ok == 1))
        cameraModel = cameraModels{selectionIdx};
        disp(['      Camera model: ' cameraModel])
    else
        error('Camera model selection cancelled by user!');
    end
end

if (~ismember(cameraModel,cameraModels))
    cameraModelsString = cell2mat(cellfun(@(x) ['"' x '"; '], cameraModels,'UniformOutput',false));
    error(['Specified camera model (' cameraModel ') does not match a known camera models (' cameraModelsString(1:end-2) ').' ]);
end

% Load camera
load([cameraModel '.mat'],'camera');

if (~exist('camera','var'))
    error(['Could not load camera model: ' cameraModel]);

end

