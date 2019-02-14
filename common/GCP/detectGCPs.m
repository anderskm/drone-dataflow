function [markers, images] = detectGCPs(imageFolder, images, flightHeight, camera, GCPs)

% To run this script fully automated, imageFolder, flightHeight,
% cameraModel and GCPfile should be set before running it. If not set, the
% user will be prompted, and the script will wait for the user to take
% action.

%% DO NOT CHANGE BELOW THIS LINE
%% Setup

disp('Setup...');

% Turn warnings on
warning on;

% Add directory and subdirectories with needed functions
% addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'common')));
% rmpath(genpath('../testing/Project point to world surface'));

%% Setup: Load marker detection settings
% See https://support.pix4d.com/hc/en-us/articles/202557469#gsc.tab=0
flightGSD = flightHeight/camera.lens.focalLengthPx*100; % Should work independent on the lens model

% Load default settings
disp('   Loading default marker detection settings...');
% [settings] = loadDefaultSettings(cameraModel);
[ settings ] = loadDefaultMarkerDetectionSettings( flightGSD, max(3, flightGSD));


%%

disp('Setup completed.');

%% Detect GCPs

oldString = [];
disp(['Detecting GCPs...' char(10)]);
warning off;
tic;
% Loop through all images and detect markers
for i = 1:length(images)
    % Display progress
    timeLeft = toc/i*(length(images)-i);
    newString = ['   Processing image (' num2str(i) '/' num2str(length(images)) '): ' images(i).name char(10) '   Time left: ' sec2dhms(timeLeft)];
    oldString = showProgress( oldString, newString );
    
    if (any(images(i).GCPsInImage))
    
    % Load image
    if (images(i).imagesPerFile > 1)
        I = im2double(imread(fullfile(imageFolder,images(i).name),images(i).imageIdx));
    else
        I = im2double(imread(fullfile(imageFolder,images(i).name)));
    end
    
    if (ndims(I) == 3)
        I = rgb2gray(I);
    end

    % Undistort image before detecting markers
    if (settings.preprocessing.undistort)
        I = p4d_undistortimage(I);
    end
    
    if (isfield(settings.markerDetection,'resizeGSD'))
        resizeScale = settings.flight.GSD/settings.markerDetection.resizeGSD;
        sizeIorig = size(I);
        I = imresize(I, resizeScale);
    end
    
    % Max and min filter of image
    Imax = ordfilt2(I, round(settings.markerDetection.diameter/2)^2,ones(round(settings.markerDetection.diameter/2)));
    Imin = ordfilt2(I, 1,ones(round(settings.markerDetection.diameter/2)));
    
    % Normalize image based on local max and min values
    I2 = (I-Imin)./(Imax-Imin);

    % Find candidate markers in the image based on the circular pattern
    markers = findMarkerCandidates(I2, settings);
    
    % Find the corners of each candidate marker
    markers = findMarkerCandidateCorners( I, markers, settings);
    
    % Classify each marker candidate as either marker or not-marker
    markers = classifyMarkers(markers, settings);

    % Read the ID of each marker
    markers = readMarkerID(I, markers, settings);
    
    % Extract thumbnail of each marker
    markers = extractMarkers(I, markers, settings);

    % Add some metadata to the markers
    for m = 1:length(markers)
        if (isfield(images(i),'outName'))
            markers(m).imageName = images(i).outName;
        else
            markers(m).imageName = images(i).name;
        end
        markers(m).imageIdx = images(i).imageIdx;
        markers(m).UAVPosition = [images(i).UTMEast images(i).UTMNorth images(i).UTMHeight];
        markers(m).UAVOrientation = [images(i).Yaw images(i).Pitch images(i).Roll];
    end;
    
    % Store markers in images struct
    images(i).markers = markers;
    images(i).allMarkers = markers;
    end
end;
warning on;

% Convert image struct to a markers struct.
[ markers ] = imageStruct2markersStruct( images );

% Rescale marker coordinates
if (isfield(settings.markerDetection,'resizeGSD'))
%     resizeScale = settings.flight.GSD/settings.markerDetection.resizeGSD;
    resizeScale = size(I)./sizeIorig;
    
    for m = 1:length(markers)
        marker = markers(m);
        marker.XY = marker.XY ./ resizeScale;
        marker.RowCol = marker.RowCol ./ resizeScale;
        marker.cornerRadii = marker.cornerRadii / mean(resizeScale);
        marker.cornersXY = marker.cornersXY ./ repmat(resizeScale,4,1);
        marker.cornersRowCol = marker.cornersRowCol ./ repmat(resizeScale,4,1);
        markers(m) = marker;
    end;
end;

% Project marker image coordinates to UTM coordinates
for m = 1:length(markers)
    [X,Y,Z] = caminvtran(markers(m).XY(1), markers(m).XY(2), camera, markers(m).UAVPosition, markers(m).UAVOrientation, flightHeight);
    markers(m).UTMEast = X;
    markers(m).UTMNorth = Y;
    markers(m).UTMHeight = Z;
end;

completionTime = toc;
disp('Detecting GCPs completed.');
disp(['   Execution time: ' sec2dhms(completionTime)])

end