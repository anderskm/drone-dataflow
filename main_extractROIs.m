clearvars;
close all;

% Pix4D-project file path - if commented or empty, a dialog box will open
% asking for it.
%p4dProjectFilepath = 'E:\Pix4D projects\20160926_VIRKN_Vraps_MS4C_for\20160926_virkn_vraps_ms4c_for.p4d';
% Reference Pix4D-project file path. If specified, the features will be calculated on (map - reference map) rather than just (map).
% p4dRefProjectFilepath = 'E:\Pix4D projects\2016.10.27-VIRKN(Ebee,RGB)efter klip\Processed data\20161027_VIRKN_RGB_efter\20161027_virkn_rgb_efter.p4d';
p4dRefProjectFilepath = 'C:\Pix4d\Drone-dataflow\2018.04.09 Mmark (Ebee, Soda)\Processed data\2018.04.09 Mmark Ebee Soda\2018.04.09_mmark_ebee_soda.p4d';

% Feature handles - function handles to functions for feature extractors.
% Must take 3 unputs; 1) Image (NxMxC), 2) mask (NxMx1) and 3) mapTransformation.
% Features extractors are not required to use all three inputs, but they must 
% only return 1 value!
featureHandles = {@(I,m,T)sum(I(m>0).*m(m>0))/sum(m(m>0)), ... % Mean value of ROI
                  @(I,m,T)median(I(m>=0.5)), ... % Median value of ROI
                  @(I,m,T)std(I(m>=0.5)), ... % Standard deviation of ROI
                  @(I,m,T)min(I(m>0.5)), ... % Minimum value of ROI
                  @(I,m,T)max(I(m>0.5)), ... % Maximum value of ROI
                  @(I,m,T)coverage_ExGR(I,m,T)}; % Coverage based on ExGR
featureNames = {'Mean','Median','Standard deviation','Minimum','Maximum','Coverage, ExGR'}; % Feature names. Must have the same number of elemtns as the feature handles.
edges = [0 6 12 18 24]/100; % Remove edges from ROIs before calculating features. Edges must be specified in meters
saveROIsAaImages = true; % 1/true = save ROIs as images
verbose = 1; % 1/true = show progress in command window. 0/false = show nothing

%% Add required functions

addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'common')));

%% Handle if no project file is specified

if (exist('p4dProjectFilepath','var'))
    if (isempty(p4dProjectFilepath))
        [p4dProjectFilepath, PathName] = uigetfile('*.p4d','Select Pix4D project-file');
        p4dProjectFilepath = fullfile(PathName, p4dProjectFilepath);
    end;
else
    [p4dProjectFilepath, PathName] = uigetfile('*.p4d','Select Pix4D project-file');
    p4dProjectFilepath = fullfile(PathName, p4dProjectFilepath);
end;

%% Handle if no project file is specified

inclRefProject = questdlg({'Would you like to include a reference project?'; ... % Question
                           'If included, features are calculated from differenceMap = map - referenceMap'; ...
                           ' '; ...
                           '** WARNING **'; ...
                           'Including a reference project takes up a lot of extra memory. It can easily use all of you available memory while extracting the ROIs. Do not expect to be able to use the computer for other purposes while extracting ROIs.'; ...
                           'Including a reference project also generally takes up more time. Expecially, if you run out of memory.'}, ...
                           'Include reference project?', ... % title
                           'Yes','No', ... % buttons
                           'No'); % Default option
if (strcmp(inclRefProject,'Yes'))
    [p4dRefProjectFilepath, PathName] = uigetfile('*.p4d','Select Pix4D REFERENCE project-file');
    p4dRefProjectFilepath = fullfile(PathName, p4dRefProjectFilepath);
    
    if (~exist(p4dRefProjectFilepath,'file'))
        warning('Expected reference project to be included, but the reference project filepath does not seem to exist. Defaulting to not including reference project');
        clear p4dRefProjectFilepath;
    end
end;

%% Find all maps associated with the project

% mapsStruct = pix4dProject2mapsStruct(p4dProjectFilepath);
% 
% [~, p4dName, p4dExt] = fileparts(p4dProjectFilepath);
% % Select maps
% [mapSelection,ok] = listdlg('ListString', fullfile({mapsStruct.type}, {mapsStruct.shortName}), ...
%                          'SelectionMode','multiple', ...
%                          'ListSize',[300 300], ...
%                          'Name','Select maps for ROI extraction', ...
%                          'PromptString',{'Select one or more maps for ROI extraction from' ; ['Pix4D-project: ' p4dName p4dExt]}, ...
%                          'OKString','OK',...
%                          'CancelString','Cancel');
% if (strcmp(ok,'OK') || (ok == 1))
%     mapsStruct = mapsStruct(mapSelection);
% else
%     error('Sheet selection cancelled by user!');
% end


%% Extract ROIs
if (exist('p4dRefProjectFilepath','var'))
    extractROIsFromPix4dProject(p4dProjectFilepath, ...
                       'refPix4dProject', p4dRefProjectFilepath, ...
                       'featureHandles', featureHandles, ...
                       'featureNames', featureNames, ...
                       'edges', edges, ...
                       'saveROIs', saveROIsAaImages, ...
                       'verbose', verbose);
else
    extractROIsFromPix4dProject(p4dProjectFilepath, ...
                           'featureHandles', featureHandles, ...
                           'featureNames', featureNames, ...
                           'edges', edges, ...
                           'mapsStruct', 'all', ...
                           'saveROIs', saveROIsAaImages, ...
                           'verbose', verbose);
end;