% clearvars;
close all;

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
        imageFolder = fullfile(flightStructs(f).path, flightStructs(f).imageFolder);
        
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
        
        % Load markers
        markers = loadMarkers(imageFolder);

        dispMarkerSummary(markers);
        
%         [markersReviewed] = reviewGCPs(markers);
        [markersReviewed, GCPs] = reviewAndAssignGCPs(markers, GCPs,'name',imageFolder);
%         markersReviewed = markers;

        disp('Reviewing detected GCPs completed.');

        % Save results temporarily, so we/you don't have to detect the markers
        % multiple times.
        saveMarkers(markersReviewed, imageFolder);

        % Display results
        dispMarkerSummary(markersReviewed);
        
%         % Assign detected GCPs to actual GCPs
%         alphabet = {'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','x','y','z'};
%         GCPpositions = [[GCPs.UTMEast]' [GCPs.UTMNorth]'];
%         stddev = 12.9; % Magic number describing the stddev of detections near a GCP
%         markerIDs = unique([markersReviewed.ID]);
%         P = zeros(length(markerIDs),length(GCPs));
%         for g = 1:length(GCPs)
%             allMarkerPos = reshape([markersReviewed.UAVPosition]',3,[])';
%             allMarkerPos = allMarkerPos(:,1:2);
% 
%             for i = 1:length(markerIDs)
%                 thisMarkerPos = reshape([markersReviewed([markersReviewed.ID] == markerIDs(i)).UAVPosition]',3,[])';
%                 thisMarkerPos = thisMarkerPos(:,1:2);
% 
%                 gaussDist = 1./(stddev*sqrt(2*pi))*exp(-(sum((thisMarkerPos-GCPpositions(g,:)).^2,2)./(2*stddev)));
%                 P(i,g) = sum(gaussDist);
%             end
%         end
%         
%         [~, GCPmarkerIDsIdx] = max(P,[],1);
%         GCPids = markerIDs(GCPmarkerIDsIdx);
%         
%         [alphabet(1:length(GCPs));num2cell(markerIDs(GCPmarkerIDsIdx))]
%         
%         for i = 1:length(GCPs)
%             GCPs(i).ID = GCPs(i).name;
%             GCPs(i).name = alphabet{i};
%         end
%         
%         for m = 1:length(markerIDs)
%             gcpIdx = find(GCPids == markerIDs(m));
%             markerIdx = find([markersReviewed.ID] == markerIDs(m));
% %             thisMarkerPos = reshape([markersReviewed([markersReviewed.ID] == markerIDs(m)).UAVPosition]',3,[])';
%             thisMarkerPos = reshape([markersReviewed(markerIdx).UAVPosition]',3,[])';
%             thisMarkerPos = thisMarkerPos(:,1:2);
%             GCPpos = GCPpositions(gcpIdx,:);
%             distances = pdist2(thisMarkerPos,GCPpos,'euclidean');
%             [~,marker2gcpIdx] = min(distances,[],2);
%             for r = 1:length(markerIdx)
%                 idx = markerIdx(r);
%                 if (~isempty(gcpIdx))
%                     markersReviewed(idx).name = GCPs(gcpIdx(marker2gcpIdx(r))).name;
%                     markersReviewed(idx).GCPidx = gcpIdx(marker2gcpIdx(r));
%                 else
%                     warning('Marker not matched to GCP!');
%                     markersReviewed(idx).GCPidx = [];
%                 end
%             end
%         end
        

        
        
        
        
%         % markerPositions = [[markersReviewed.UTMEast]' [markersReviewed.UTMNorth]'];
%         markerIDs = unique([markersReviewed.ID]);
%         markerPositions = zeros(length(markerIDs),2);
%         for i = 1:length(markerIDs)
%             %markerPositions(i,:) = mean([[markersReviewed([markersReviewed.ID] == markerIDs(i)).UTMEast]' [markersReviewed([markersReviewed.ID] == markerIDs(i)).UTMNorth]'],1);
%             pos = mean(reshape([markersReviewed([markersReviewed.ID] == markerIDs(i)).UAVPosition]',3,[])',1);
%             markerPositions(i,:) = pos(1:2);
%         end
%         GCPpositions = [[GCPs.UTMEast]' [GCPs.UTMNorth]'];
%         costMat = pdist2(GCPpositions, markerPositions);
%         [assignment,cost] = munkres(costMat);
% 
%         for i = 1:length(GCPs)
%             GCPs(i).ID = GCPs(i).name;
%             GCPs(i).name = alphabet{i};
%         end;
% 
%         for i = 1:length(markersReviewed)
%             uniqueMarkerIdIdx = find(markerIDs == markersReviewed(i).ID);
%             GCPid = find(assignment(:,uniqueMarkerIdIdx));
%             markersReviewed(i).name = GCPs(GCPid).name;
%         end;
        
        flightStructs(f).markersReviewed = markersReviewed;
        flightStructs(f).GCPs = GCPs;

        % Plot markers on Coverage map
%         [X, Y] = meshgrid(linspace(min([images.cx]),max([images.cx]),1000),linspace(min([images.cy]),max([images.cy]),1000));
%         C = zeros(size(X));
%         for i = 1:length(images)
%             in = inpolygon(X, Y, images(i).cx, images(i).cy);
%             C = C + in;
%         end;

        figure;
%         image([min(X) max(X)],[min(Y) max(Y)],C,'CDataMapping','scaled');
        hold on;
        for m = 1:length(markersReviewed)
%             uniqueMarkerIdIdx = find(markerIDs == markersReviewed(m).ID);
%             GCPid = find(assignment(:,uniqueMarkerIdIdx));
            GCPid = markersReviewed(m).GCPidx;
            markerPos = markersReviewed(m).UAVPosition + rand(1,3)*10-5;
            plot([markerPos(1) GCPs(GCPid).UTMEast],[markerPos(2) GCPs(GCPid).UTMNorth],'r-')
            image(markerPos(1)+[-.5 .5], markerPos(2)+[-.5 .5], repmat(markersReviewed(m).thumbnail.ImageRotated,1,1,3));
            text(markerPos(1), markerPos(2), num2str(markersReviewed(m).ID))
        end;
        axis equal;
%         plot([GCPs.UTMEast]', [GCPs.UTMNorth]','rx','MarkerSize',15,'LineWidth',2)
        text([GCPs.UTMEast]', [GCPs.UTMNorth]',{GCPs.name},'HorizontalAlignment','center','VerticalAlignment','Middle');
        axis image;
        colorbar
        title('Coverage and GCPs');
        xlabel('East, m');
        xlabel('North, m');


        % Export GCPs: Select output folder
        disp('Exporting GCPs...')
        outputFolder = imageFolder;

        disp(['   Output folder: ' outputFolder]);

        % Export GCPs: GCPs in world
        disp(['   Exporting GCPs in world coordinates...']);
        outputFile = fullfile(outputFolder,'GCPs_in_world.csv');

        GCPnames = {GCPs.name};
        GCPutmEast = [GCPs.UTMEast];
        GCPutmNorth = [GCPs.UTMNorth];
        GCPutmHeight = [GCPs.UTMHeigt];
        disp(['      Output file: ' outputFile]);
        writeGCP2pix4d(outputFile, GCPnames, GCPutmEast, GCPutmNorth, GCPutmHeight);

%         for m = 1:length(markersReviewed)
%             name = markersReviewed(m).imageName;
%             [~,name,ext] = fileparts(name);
%             name = [name(1:end-2) ext];
%             markersReviewed(m).imageName = name;
%         end

        % Export GCPs: GCPs in images
        disp(['   Exporting GCPs in image coordinates...']);
        GCPfilename = fullfile(outputFolder, 'GCPs_in_images.csv');
        disp(['      Output file: ' GCPfilename]);
        exportMarkers( GCPfilename, markersReviewed );

        % Export GCPs: Done
        disp('Exporting GCPs completed.');

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
