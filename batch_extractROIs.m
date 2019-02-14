% clearvars;
close all;

%%

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

%% DO NOT CHANGE BELOW THIS LINE
%% Setup

% Add directory and subdirectories with needed functions
addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'common')));

%% Extract ROIs

exceptionsCaught = struct([]);

for f = 1:length(flightStructs)
    disp(['Processing flight (' num2str(f) '/' num2str(length(flightStructs)) '):']);
    disp(flightStructs(f));
    
    try
        p4dProjectFilepath = fullfile(flightStructs(f).path, flightStructs(f).p4dProject);
        ROIfiles = flightStructs(f).ROIfiles;
        for r = 1:length(ROIfiles)
            ROIfile = fullfile(flightStructs(f).path, ROIfiles{r});
            extractROIsFromPix4dProject(p4dProjectFilepath, ...
                       'featureHandles', featureHandles, ...
                       'featureNames', featureNames, ...
                       'edges', edges, ...
                       'mapsStruct', 'all', ...
                       'ROIfile', ROIfile, ...
                       'saveROIs', saveROIsAaImages, ...
                       'verbose', verbose);
        end

    catch ME
        disp('***** ERROR CAUGHT *****');
        disp('See the struct array exceptionsCaught for more information.');
        exceptionStruct.ME = ME;
        exceptionStruct.index = [f r];
        exceptionStruct.flightStruct = flightStructs(f);
        if (isempty(exceptionsCaught))
            exceptionsCaught = exceptionStruct;
        else    
            exceptionsCaught(end+1) = exceptionStruct;
        end
    end
end

disp('Batch processing completed!');
disp([num2str(length(exceptionsCaught)) ' exceptions caught!'])
