clearvars;
close all;

% Press F5 or the "Run" button (green triangle) to run the script

%% Settings

% Specify Geoid for images
imageGeoidWgs84ToEgm96 = 0;
% If set to 1/True, image coordinates are converted from wgs84 to egm96 (e.g. when using Sequioa with Phantom)
% If set to 0/False, image coordinates are not converted from wgs84 to egm96

% Set the expected flight height. If the median flight height is outside
% this range, the script will throw an error. First value is the lower
% bound and the second value is the upper bound. Both values are in meters.
expectedFlightHeight = [30 70];

% Thresholds for GCP co-linearity. Both thresholds specify a limit to the
% ratio between the "length" and the "width" of how far the GCPs are spread out
% in the world. The larger the number, the more co-linear (bad).
GCPelongationWarningThreshold = 10; % Threshold for throwing a warning. Script continues.
GCPelongationErrorThreshold = 100; % Threshold for throwing an error. Scripts stops.

%% DO NOT CHANGE BELOW THIS LINE
%% Setup

% Add directory and subdirectories with needed functions
addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'common')));

%% Setup: Locate images
disp('   Detecting images...');

[images, imageFolder, imgExt] = listImages();

if (isempty(images))
    error('No images detected in folder.');
end

%% Setup: Camera model

% Attempt to detect the camera model
[cameraModel] = detectCameraModel(imageFolder, images(1).name);
% Load the camera model (if the camera model could not be detected, the
% user will be prompted)
camera = loadCamera(cameraModel);

if (isempty(camera))
    error('Loaded camera is empty!');
end

%% Setup: GCP coordinates

if (~exist('GCPfile','var'))

    [xlsGCPfile, xlsGCPfolder] = uigetfile({'*.xlsx';'*.xls'},'Select Excel spreadsheet with GCPs.',imageFolder);
    GCPfile = fullfile(xlsGCPfolder, xlsGCPfile);
end

% Select sheet in spreadsheet
[ sheet, sheets ] = xlsSelectSheet( GCPfile );

disp(['GCP sheet              : ' sheet]);

% Load ROI file
if (exist(GCPfile,'file'))
    [ GCPs, GCPheader ] = readGCPfromXLS( GCPfile, sheet );
else
    error(['GCP file does not exist: ' GCPfile]);
end;

disp('GCP header:');
disp(GCPheader)

% Convert to UTM
utmStruct = defaultm('utm');
utmStruct.zone = utmzone(GCPheader.Latitude, GCPheader.Longitude);
utmStruct.geoid = wgs84Ellipsoid();
utmStruct = defaultm(utmStruct);

for i = 1:length(GCPs)
    [x,y,z] = mfwdtran(utmStruct, GCPs(i).latitude, GCPs(i).longitude, GCPs(i).altitude);
    GCPs(i).UTMEast = x;
    GCPs(i).UTMNorth = y;
    GCPs(i).UTMHeigt = z;
end;

%% Setup: Get image positions and orientations from Exif tags
% Position --> latitude, longitude and altitude
% Orientation --> yaw, pitch and roll

[~, ~, imgExt] = fileparts(images(1).name);
imgExt = imgExt(2:end); % Remove . in file extension. E.g.: ".tif" --> "tif"

% Set exif tags for extraction
ExifTags = {'GPSLatitude', 'GPSLongitude', 'GPSAltitude','GPSXYAccuracy','GPSZAccuracy', 'Yaw', 'Pitch', 'Roll'};
% Set filename of output csv-file
outputCsvFilename = fullfile(imageFolder, 'ExifTags.csv');
% Call ExifTool to extract exif tags and store them in csv-file
[ outputCsvFilename ] = exiftoolExtractTagsToCSV(ExifTags, imageFolder, ['*.' imgExt], outputCsvFilename, true );
% Read exif tags from csv-file
[ exifTagStruct ] = readExifToolCSV( outputCsvFilename, true );
% Check if GPS coordinates and altitude was set; if not, throw error
if (~isfield(exifTagStruct,'GPSLatitude') || ~isfield(exifTagStruct,'GPSLongitude') || ~isfield(exifTagStruct,'GPSAltitude'))
    error('Could not read GPSLatitude, GPSLongitude or GPSAltitude from images in specified folder. Please make sure, that the images are geotagged!');
end
% Parse raw exif tags
[ exifTagStruct ] = parseExifToolTagStruct( exifTagStruct, true );

% % Uncomment tor testing yaw, pitch and roll estimation
% exifTagStruct = rmfield(exifTagStruct,'Yaw');
% exifTagStruct = rmfield(exifTagStruct,'Pitch');
% exifTagStruct = rmfield(exifTagStruct,'Roll');

% Check if yaw, pitch and roll are set
% If not, estimate yaw, and set pitch and roll to 0.
if (~isfield(exifTagStruct,'Yaw'))
    warning('Yaw could not be read from Exif data. Etimating yaw.');
    % Grap GPS coordinates
    lat = [exifTagStruct.GPSLatitude];
    lon = [exifTagStruct.GPSLongitude];
    % Convert to UTM coordinates
    utmStruct = defaultm('utm');
    utmStruct.zone = utmzone(mean(lat), mean(lon));
    utmStruct.geoid = wgs84Ellipsoid();
    utmStruct = defaultm(utmStruct);
    [E, N] = mfwdtran(utmStruct, lat, lon);
    % Estimate Yaw
    Yaw = estimateYaw(N, E);
    % Store in exifTagStruct
    for i = 1:length(exifTagStruct)
        exifTagStruct(i).Yaw = Yaw(i);
    end
end
% Check if Pitch is set
if (~isfield(exifTagStruct,'Pitch'))
    warning('Pitch could not be read from Exif data. Setting pitch to 0 for all images.');
    % Set pitch to 0 for all images
    Pitch = zeros(1, length(exifTagStruct));
    % Store in exifTagStruct
    for i = 1:length(exifTagStruct)
        exifTagStruct(i).Pitch = Pitch(i);
    end
end
% Check if Roll is set
if (~isfield(exifTagStruct,'Roll'))
    warning('Roll could not be read from Exif data. Setting roll to 0 for all images.');
    % Set roll to 0 for all images
    Roll = zeros(1, length(exifTagStruct));
    % Store in exifTagStruct
    for i = 1:length(exifTagStruct)
        exifTagStruct(i).Roll = Roll(i);
    end
end

% Check if image and exift names match
% [Lia, Locb] = ismember({exifTagStruct.SourceFile}, {images.name});
[Lia, Locb] = ismember({images.name}, {exifTagStruct.SourceFile});
if (sum(Lia) ~= length(images))
    error('Could not match exif data to all images!');
end

% Copy all exif tags to images
for i = 1:length(Locb)
    exifIdx = Locb(i);
    tags = fieldnames(exifTagStruct(exifIdx));
    for t = 1:length(tags)
        images(i).(tags{t}) = exifTagStruct(exifIdx).(tags{t});
    end
end

%% Setup: Convert GPS lat/lon to UTM E/N

% Setup common UTM struct - assume same zone for all images
lat = mean([images.GPSLatitude]);
lon = mean([images.GPSLongitude]);
utmStruct = defaultm('utm');
utmStruct.zone = utmzone(lat, lon);
utmStruct.geoid = wgs84Ellipsoid();
utmStruct = defaultm(utmStruct);

for i = 1:length(images)
    [utmX, utmY, utmZ] = mfwdtran(utmStruct, images(i).GPSLatitude, images(i).GPSLongitude, images(i).GPSAltitude);
    if exist('imageGeoidWgs84ToEgm96','var')
        if (imageGeoidWgs84ToEgm96)
            geoidHeightEgm96 = geoidheight(images(i).GPSLatitude, images(i).GPSLongitude, 'EGM96');
        else
            geoidHeightEgm96 = 0;
        end
    else
        geoidHeightEgm96 = 0;
    end
    images(i).UTMNorth = utmY;
    images(i).UTMEast = utmX;
    images(i).UTMHeight = utmZ+geoidHeightEgm96;
    images(i).Position = [utmX, utmY, utmZ];
    images(i).Orientation = [images(i).Yaw, images(i).Pitch, images(i).Roll];
end

%% Setup: Flight height

[planeParams, inliers, residuals] = fitplane2GCPs(GCPs);

flightHeight = heightFromPlane([images.UTMEast], [images.UTMNorth], [images.UTMHeight], planeParams);

if (~exist('flightHeight','var'))

    answer = inputdlg('What was the the flight altitude (in meters)?','Flight altitude');
    answer = strrep(answer,',','.');
    flightHeight = str2double(answer)*ones(size(images));
end

for i = 1:length(images)
    images(i).flightHeight = flightHeight(i);
end

medianFlightHeight = median(flightHeight,'omitnan');

disp(['Median flight height: ' num2str(medianFlightHeight,'%.1f') ' m']);

%% Setup: Check if GCP might be in image
for i = 1:length(images)
    [ c_ul ] = camLine2PlanteIntersection(camera.image.cornerLines.l_ul, images(i).Position, images(i).Orientation, images(i).flightHeight, planeParams(1:3) );
    [ c_ur ] = camLine2PlanteIntersection(camera.image.cornerLines.l_ur, images(i).Position, images(i).Orientation, images(i).flightHeight, planeParams(1:3) );
    [ c_lr ] = camLine2PlanteIntersection(camera.image.cornerLines.l_lr, images(i).Position, images(i).Orientation, images(i).flightHeight, planeParams(1:3) );
    [ c_ll ] = camLine2PlanteIntersection(camera.image.cornerLines.l_ll, images(i).Position, images(i).Orientation, images(i).flightHeight, planeParams(1:3) );
    cx = [c_ul(1), c_ur(1), c_lr(1), c_ll(1)];
    cy = [c_ul(2), c_ur(2), c_lr(2), c_ll(2)];
    
    GCPsInImage = inpolygon([GCPs.UTMEast],[GCPs.UTMNorth],cx, cy);
    
    images(i).cx = cx;
    images(i).cy = cy;
    images(i).GCPsInImage = GCPsInImage; % ones(1,length(GCPs),'logical'); % 
end

numImagesWithGCPs = sum(any(reshape([images.GCPsInImage],length(GCPs),[])));
disp(['GCPs potentially present in ' num2str(numImagesWithGCPs) ' out of ' num2str(length(images)) ' images.']);

%% GCP and image sanity check

% Check for potential GCP co-linearity
% Fit line to GCPs. Generally, a poor fit is expected. If good fit, GCPs
% are co-linear.
[lineParams, dist] = fitline([[GCPs.UTMEast];[GCPs.UTMNorth]]);
% Calculate max distance between GCPs projected onto line
x = (lineParams(2)*(lineParams(2)*[GCPs.UTMEast] - lineParams(1)*[GCPs.UTMNorth]) - lineParams(1)*lineParams(3))/(sum(lineParams(1:2).^2));
y = (lineParams(1)*(-lineParams(2)*[GCPs.UTMEast] + lineParams(1)*[GCPs.UTMNorth]) - lineParams(2)*lineParams(3))/(sum(lineParams(1:2).^2));
GCPlineLength = max(max(pdist2([x' y'],[x' y'])));

% Calculate median distance from GCPs to line
medianGCPdist2line = median(abs([GCPs.UTMEast;GCPs.UTMNorth;ones(size(GCPs))]'*lineParams/sqrt(sum(lineParams(1:2).^2))));

% Check if length/width ratio is outside expected range
if (GCPlineLength/medianGCPdist2line > GCPelongationErrorThreshold)
    error(['GCPs are co-linear!' newline() 'Using best line fit, the ratio (' num2str(GCPlineLength/medianGCPdist2line,'%.1f') ') between the length of the GCP line (' num2str(GCPlineLength,'%.1f') ' m) and the median distance to line (' num2str(medianGCPdist2line,'%.1f') ' m) is larger than expected (' num2str(GCPelongationErrorThreshold,'%.1f') ').' newline() 'To suppress this error, set the variable GCPelongationErrorThreshold to a larger value (default: 100).']);
elseif (GCPlineLength/medianGCPdist2line > GCPelongationWarningThreshold)
    warning(['GCPs might be co-linear' newline() 'Using best line fit, the ratio (' num2str(GCPlineLength/medianGCPdist2line,'%.1f') ') between the length of the GCP line (' num2str(GCPlineLength,'%.1f') ' m) and the median distance to line (' num2str(medianGCPdist2line,'%.1f') ' m) is larger than expected (' num2str(GCPelongationWarningThreshold,'%.1f') ').' newline() 'To suppress this warning, set the variable GCPelongationWarningThreshold to a larger value (default: 10).']);
end


% Check if all GCPs are within convex hull of the image coverage
imagesX = [images.UTMEast];
imagesY = [images.UTMNorth];
convHullIdx = convhull(imagesX,imagesY);
GCPsInPolygon = inpolygon([GCPs.UTMEast],[GCPs.UTMNorth],imagesX(convHullIdx), imagesY(convHullIdx));
if (sum(GCPsInPolygon) < 3)
    figure;
    plot(imagesX,imagesY,'bs');
    hold on;
    plot(imagesX(convHullIdx),imagesY(convHullIdx),'b-');
    plot([GCPs(GCPsInPolygon).UTMEast],[GCPs(GCPsInPolygon).UTMNorth],'gx','MarkerSize',10,'LineWidth',2);
    plot([GCPs(~GCPsInPolygon).UTMEast],[GCPs(~GCPsInPolygon).UTMNorth],'rx','MarkerSize',10,'LineWidth',2);
    axis equal;
    legend('Image locations','Convex hull of image locations','GCPs in convex hull','GCPs outside convex hull','Location','EastOutside');
    error('Expected at least 4 GCPs to be within convex hull of image position.');
end

% Check flight heights
if (medianFlightHeight < min(expectedFlightHeight)) || (medianFlightHeight > max(expectedFlightHeight))
    error(['Median flight height (' num2str(medianFlightHeight,'%.1f') ' m) is outside expected flight height ([' num2str(expectedFlightHeight,'%.1f m, ') '])']);
end

flightGSD = median(flightHeight)/camera.lens.focalLengthPx*100;
disp(['GSD: ' num2str(flightGSD,'%.3f') ' cm/px']);

%% Detect GCPs

% Call common GCP detection script
[markers, images] = detectGCPs(imageFolder, images, medianFlightHeight, camera, GCPs);

% Save results temporarily, so we/you don't have to detect the markers
% multiple times.
saveMarkers(markers, imageFolder);

% Display results
dispMarkerSummary(markers);

%% Review GCPs

% Load markers
markers = loadMarkers(imageFolder);

% [markersReviewed] = reviewGCPs(markers);
[markersReviewed, GCPs] = reviewAndAssignGCPs(markers, GCPs,'name',imageFolder);

dispMarkerSummary(markersReviewed);

disp('Reviewing detected GCPs completed.');

%% Assign detected GCPs to actual GCPs
% alphabet = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','x','y','z'};
% 
% % markerPositions = [[markersReviewed.UTMEast]' [markersReviewed.UTMNorth]'];
markerIDs = unique([markersReviewed.ID]);
% markerPositions = zeros(length(markerIDs),2);
% for i = 1:length(markerIDs)
%     %markerPositions(i,:) = mean([[markersReviewed([markersReviewed.ID] == markerIDs(i)).UTMEast]' [markersReviewed([markersReviewed.ID] == markerIDs(i)).UTMNorth]'],1);
%     pos = mean(reshape([markersReviewed([markersReviewed.ID] == markerIDs(i)).UAVPosition]',3,[])',1);
%     markerPositions(i,:) = pos(1:2);
% end
% GCPpositions = [[GCPs.UTMEast]' [GCPs.UTMNorth]'];
% costMat = pdist2(GCPpositions, markerPositions);
% [assignment,cost] = munkres(costMat);
% 
% for i = 1:length(GCPs)
%     GCPs(i).ID = GCPs(i).name;
%     GCPs(i).name = alphabet{i};
% end;
% 
% for i = 1:length(markersReviewed)
%     uniqueMarkerIdIdx = find(markerIDs == markersReviewed(i).ID);
%     GCPid = find(assignment(:,uniqueMarkerIdIdx));
% %     GCPid = minIdx(i);
%     markersReviewed(i).name = GCPs(GCPid).name;
% end;

%% Coverage

[X, Y] = meshgrid(linspace(min([images.cx]),max([images.cx]),1000),linspace(min([images.cy]),max([images.cy]),1000));
C = zeros(size(X));
for i = 1:length(images)
    in = inpolygon(X, Y, images(i).cx, images(i).cy);
    C = C + in;
end

%%

figure;
image([min(X(:)) max(X(:))]-mean(X(:)),[min(Y(:)) max(Y(:))]-mean(Y(:)),C,'CDataMapping','scaled');
hold on;
markersReviewed2 = markersReviewed([markersReviewed.isMarker]);
for m = 1:length(markersReviewed2)
%     image(markersReviewed(m).UTMEast+[-.5 .5], markersReviewed(m).UTMNorth+[-.5 .5], repmat(markersReviewed(m).thumbnail.ImageRotated,1,1,3));
%     text(markersReviewed(m).UTMEast, markersReviewed(m).UTMNorth, num2str(markersReviewed(m).ID))
%     plot([markersReviewed(m).UTMEast markersReviewed(m).UAVPosition(1)],[markersReviewed(m).UTMNorth markersReviewed(m).UAVPosition(2)],'r-x');
    uniqueMarkerIdIdx = find(markerIDs == markersReviewed2(m).ID);
%     GCPid = find(assignment(:,uniqueMarkerIdIdx));
    GCPid = markersReviewed2(m).GCPidx;
%     GCPid = minIdx(m);
    markerPos = markersReviewed2(m).UAVPosition + rand(1,3)*10-5;
%     markerPos = [markersReviewed(m).UTMEast markersReviewed(m).UTMNorth markersReviewed(m).UTMHeight] + rand(1,3)*10-5;
    plot([markerPos(1) GCPs(GCPid).UTMEast]-mean(X(:)),[markerPos(2) GCPs(GCPid).UTMNorth]-mean(Y(:)),'r-')
    image(markerPos(1)+[-.5 .5]-mean(X(:)), markerPos(2)+[-.5 .5]-mean(Y(:)), repmat(markersReviewed2(m).thumbnail.ImageRotated,1,1,3));
    text(markerPos(1)-mean(X(:)), markerPos(2)-mean(Y(:)), num2str(markersReviewed2(m).ID))
end
axis equal;
axis xy;
plot([GCPs.UTMEast]'-mean(X(:)), [GCPs.UTMNorth]'-mean(Y(:)),'rx','MarkerSize',15,'LineWidth',2)
axis image;
colorbar
title('Coverage and GCPs');
xlabel('East, m');
ylabel('North, m');

%% Export GCPs: Select output folder
disp('Exporting GCPs...')

% outputFolder = uigetdir(imageFolder,'Select output folder for GCPs');
% if (outputFolder == 0)
%     error('Folder selection cancelled by user.');
% end
outputFolder = imageFolder;
disp(['   Output folder: ' outputFolder]);

%% Export GCPs: GCPs in world

disp(['   Exporting GCPs in world coordinates...']);
outputFile = fullfile(outputFolder,'GCPs_in_world.csv');

GCPnames = {GCPs.name};
GCPutmEast = [GCPs.UTMEast];
GCPutmNorth = [GCPs.UTMNorth];
GCPutmHeight = [GCPs.UTMHeigt];
disp(['      Output file: ' outputFile]);
writeGCP2pix4d(outputFile, GCPnames, GCPutmEast, GCPutmNorth, GCPutmHeight);


%% Export GCPs: GCPs in images

disp(['   Exporting GCPs in image coordinates...']);

GCPfilename = fullfile(outputFolder, 'GCPs_in_images.csv');

disp(['      Output file: ' GCPfilename]);
exportMarkers( GCPfilename, markersReviewed );

%% Export GCPs: Done

disp('Exporting GCPs completed.');

%% DONE

disp('DONE!');
