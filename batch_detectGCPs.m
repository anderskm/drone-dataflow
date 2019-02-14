% clearvars;
close all;

%% Flags

% Specify Geoid for images
imageGeoidWgs84ToEgm96 = 1;
% If set to 1/True, image coordinates are converted from wgs84 to egm96 (e.g. when using Sequioa with Phantom)
% If set to 0/False, image coordinates are not converted from wgs84 to egm96

%% DO NOT CHANGE BELOW THIS LINE
%% Setup

% Add directory and subdirectories with needed functions
addpath(genpath(fullfile(fileparts(mfilename('fullpath')),'common')));

%%

%% Detect GCPs

exceptionsCaught = struct([]);

for f = 1:length(flightStructs)
    disp(['Processing flight (' num2str(f) '/' num2str(length(flightStructs)) '):']);
    disp(flightStructs(f));
    
    try
        % Locate images
        imageFolder = fullfile(flightStructs(f).path, flightStructs(f).imageFolder);
        [images, imageFolder, imgExt] = listImages(imageFolder);
        if (isempty(images))
            error('No images detected in folder.');
        end

        % Load camera
        camera = loadCamera(flightStructs(f).cameraModel);
        if (isempty(camera))
            error('Loaded camera is empty!');
        end

%         % Set flight height
%         logFile = fullfile(flightStructs(f).path, flightStructs(f).logFile);
%         [ flightHeight, groundLevel, flightLevel ] = bbx2flightHeight( logFile );
%         disp(['Ground level : ' num2str(groundLevel,'%.1f') ' m']);
%         disp(['Flight level : ' num2str(flightLevel,'%.1f') ' m']);
%         disp(['Flight height: ' num2str(flightHeight,'%.1f') ' m']);
        
%         flightStructs(f).flightHeight = flightHeight;

        % Load GCPs
        GCPfile = fullfile(flightStructs(f).path, flightStructs(f).GCPfile);
        % Select sheet in spreadsheet
        [ sheet, sheets ] = xlsSelectSheet( GCPfile, 1 ); % Always select first sheet

        disp(['GCP sheet              : ' sheet]);

        % Load GCP file
        if (exist(GCPfile,'file'))
            [ GCPs, GCPheader ] = readGCPfromXLS( GCPfile, sheet );
        else
            error(['GCP file does not exist: ' GCPfile]);
        end

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
        end
        
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
%         [Lia, Locb] = ismember({exifTagStruct.SourceFile}, {images.name});
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
            images(i).UTMHeight = utmZ;
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

        medianFlightHeight = median(flightHeight(~isnan(flightHeight)));

        disp(['Median flight height: ' num2str(medianFlightHeight,'%.1f') ' m']);

        %% Setup: Check if GCP might be in image
        for i = 1:length(images)
            [ c_ul ] = camLine2PlanteIntersection(camera.image.cornerLines.l_ul, images(i).Position, images(i).Orientation, images(i).flightHeight );
            [ c_ur ] = camLine2PlanteIntersection(camera.image.cornerLines.l_ur, images(i).Position, images(i).Orientation, images(i).flightHeight );
            [ c_lr ] = camLine2PlanteIntersection(camera.image.cornerLines.l_lr, images(i).Position, images(i).Orientation, images(i).flightHeight );
            [ c_ll ] = camLine2PlanteIntersection(camera.image.cornerLines.l_ll, images(i).Position, images(i).Orientation, images(i).flightHeight );
            cx = [c_ul(1), c_ur(1), c_lr(1), c_ll(1)];
            cy = [c_ul(2), c_ur(2), c_lr(2), c_ll(2)];

            GCPsInImage = inpolygon([GCPs.UTMEast],[GCPs.UTMNorth],cx, cy);

            images(i).cx = cx;
            images(i).cy = cy;
            images(i).GCPsInImage = GCPsInImage;
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
        GCPelongationWarningThreshold = 10;
        GCPelongationErrorThreshold = 100;
        if (GCPlineLength/medianGCPdist2line > GCPelongationErrorThreshold)
            error(['GCPs are co-linear!' newline() 'Using best line fit, the ratio (' num2str(GCPlineLength/medianGCPdist2line,'%.1f') ') between the length of the GCP line (' num2str(GCPlineLength,'%.1f') ' m) and the median distance to line (' num2str(medianGCPdist2line,'%.1f') ' m) is larger than expected (' num2str(GCPelongationErrorThreshold,'%.1f') ').' newline() 'To suppress this error, set the variable GCPelongationErrorThreshold to a larger value (default: 100).']);
        elseif (GCPlineLength/medianGCPdist2line > GCPelongationWarningThreshold)
            warning(['GCPs might be co-linear' newline() 'Using best line fit, the ratio (' num2str(GCPlineLength/medianGCPdist2line,'%.1f') ') between the length of the GCP line (' num2str(GCPlineLength,'%.1f') ' m) and the median distance to line (' num2str(medianGCPdist2line,'%.1f') ' m) is larger than expected (' num2str(GCPelongationWarningThreshold,'%.1f') ').' newline() 'To suppress this warning, set the variable GCPelongationWarningThreshold to a larger value (default: 10).']);
        end


        % Check if all GCPs are within convex hull of the image coverage
        imagesX = [images.cx];
        imagesY = [images.cy];
        convHullIdx = convhull(imagesX,imagesY);
        GCPsInPolygon = inpolygon([GCPs.UTMEast],[GCPs.UTMNorth],imagesX(convHullIdx), imagesY(convHullIdx));
        if (~all(GCPsInPolygon))
            figure;
            plot(imagesX,imagesY,'bs');
            hold on;
            plot(imagesX(convHullIdx),imagesY(convHullIdx),'b-');
            plot([GCPs(GCPsInPolygon).UTMEast],[GCPs(GCPsInPolygon).UTMNorth],'gx','MarkerSize',10,'LineWidth',2);
            plot([GCPs(~GCPsInPolygon).UTMEast],[GCPs(~GCPsInPolygon).UTMNorth],'rx','MarkerSize',10,'LineWidth',2);
            axis equal;
            legend('Image locations','Convex hull of image locations','GCPs in convex hull','GCPs outside convex hull','Location','EastOutside');
            error('Expected all GCPs to be within convex hull of image position.');
        end

        % Check flight heights
        expectedFlightHeight = [40 70];
        if (medianFlightHeight < min(expectedFlightHeight)) || (medianFlightHeight > max(expectedFlightHeight))
            error(['Median flight height (' num2str(medianFlightHeight,'%.1f') ' m) is outside expected flight height ([' num2str(expectedFlightHeight,'%.1f m, ') '])']);
        end

        % Call common GCP detection script
        [markers, images] = detectGCPs(imageFolder, images, medianFlightHeight, camera, GCPs);

        % Save results temporarily, so we/you don't have to detect the markers
        % multiple times.
        saveMarkers(markers, imageFolder);

        % Display results
        dispMarkerSummary(markers);
    
    catch ME
        disp('***** ERROR CAUGHT *****');
        disp('See the struct array exceptionsCaught for more information.');
        exceptionStruct.ME = ME;
        exceptionStruct.index = f;
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
