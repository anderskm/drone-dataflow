clearvars;
close all;

margin = 1; % m. Distance to skip outside ROI
width = 1; % m. Width of new ROI to either of the short ends

%
%    width     margin                                                   margin     width
%   <-----> <---------->                                             <----------> <----->
%                                                                 
%  +-------+            +-------------------------------------------+            +-------+
%  |       |            |                                           |            |       |
%  |  New  |            |                                           |            |  New  |
%  |  ROI  |            |                   ROI                     |            |  ROI  |
%  | "LEFT"|            |             (parcel / plot)               |            |"RIGHT"|
%  |       |            |                                           |            |       |
%  +-------+            +-------------------------------------------+            +-------+
%  
%


%%
addpath(genpath('../common'));

%% Spreadsheet selection

[xlsROIfile, xlsROIfolder] = uigetfile({'*.xlsx';'*.xls'},'Select Excel spreadsheet with ROIs.');
xlsFullfile = fullfile(xlsROIfolder, xlsROIfile);

% Sheet selection
disp(['ROI spreadsheet folder : ' xlsROIfolder]);
disp(['ROI spreadsheet        : ' xlsROIfile]);

[ sheet, sheets ] = xlsSelectSheet( xlsFullfile );

disp(['ROI sheet              : ' sheet]);

%% Read ROIs from XLS sheet

[ ROIs, ROIheader ] = readROIfromXLS( xlsFullfile, sheet );

disp('ROI header:');
disp(ROIheader)
disp('ROI areas:');
disp(ROIheader.Area)

%% Calculate UTM coordinates of ROIs

% Assume all points are in the same UTM zone (if not, they should be close
% enough to the border that the error is sufficiently small)
zone = utmzone(ROIs(1).latitude, ROIs(1).longitude);
[ellipsoid,estr] = utmgeoid(zone);
mstruct = defaultm('utm');
mstruct.zone = zone;
mstruct.geoid = ellipsoid;
mstruct = defaultm(mstruct);
for r = 1:length(ROIs)
    ROI = ROIs(r);
    [X, Y, Z] = mfwdtran(mstruct, ROI.latitude, ROI.longitude, ROI.altitude);
    ROIs(r).E = X;
    ROIs(r).N = Y;
    ROIs(r).Z = Z;
end

%%

for i = 1:length(ROIs)
    ROI = ROIs(i);

    X = ROI.E;
    Y = ROI.N;

    theta = atan2d(Y-mean(Y), X-mean(X));

    [~, sort_idx] = sort(theta);

    X = X(sort_idx);
    Y = Y(sort_idx);

    d12 = sqrt((X(1)-X(2))^2 + (Y(1)-Y(2))^2);
    d23 = sqrt((X(2)-X(3))^2 + (Y(2)-Y(3))^2);
    d34 = sqrt((X(3)-X(4))^2 + (Y(3)-Y(4))^2);
    d40 = sqrt((X(4)-X(1))^2 + (Y(4)-Y(1))^2);

    if (d12 + d34 > d23 + d40)
        longside_idx = [1 2 3 4];
        shortside_idx = [2 3 4 1];
    else
        longside_idx = [2 3 4 1];
        shortside_idx = [1 2 3 4];
    end

    ROIs(i).E = X;
    ROIs(i).N = Y;
    ROIs(i).Z = ROI.Z(sort_idx);
    ROIs(i).longitude = ROI.longitude(sort_idx);
    ROIs(i).latitude = ROI.latitude(sort_idx);
    ROIs(i).altitude = ROI.altitude(sort_idx);
    ROIs(i).longside_idx = longside_idx;
    ROIs(i).shortside_idx = shortside_idx;

%     ROIs(i) = ROI;
     
end

%%

ROIs_right_corners = nan(length(ROIs), 4, 2);
ROIs_left_corners = nan(length(ROIs), 4, 2);

for i = 1:length(ROIs)
    ROI = ROIs(i);
    longside_idx = ROI.longside_idx;
    shortside_idx = ROI.shortside_idx;

    X = ROI.E;
    Y = ROI.N;
   
    X_offset = mean(X);
    Y_offset = mean(Y);
   
    X = X-X_offset;
    Y = Y-Y_offset;

    v1 = [X(longside_idx(2))-X(longside_idx(1)), Y(longside_idx(2))-Y(longside_idx(1))];
    u1 = v1/norm(v1);
    v2 = [X(longside_idx(3))-X(longside_idx(4)), Y(longside_idx(3))-Y(longside_idx(4))]; % Swap large and small index to ensure, that the two lines point in the same general direction
    u2 = v2/norm(v2);
    
    roi_right_corners = [[X(longside_idx(2)), Y(longside_idx(2))]+[u1*margin; u1*(margin+width)]; [X(longside_idx(3)), Y(longside_idx(3))]+[u2*(margin+width); u2*margin]];
    roi_left_corners  = [[X(longside_idx(1)), Y(longside_idx(1))]-[u1*margin; u1*(margin+width)]; [X(longside_idx(4)), Y(longside_idx(4))]-[u2*(margin+width); u2*margin]];
    
    ROIs_right_corners(i,:,:) = roi_right_corners + [X_offset, Y_offset];
    ROIs_left_corners(i,:,:) = roi_left_corners + [X_offset, Y_offset];

end

%% Export to xlsx (RIGHT)
name_parts = strsplit(xlsROIfile,'.');
output_filename = fullfile(xlsROIfolder, [name_parts{1} '__RIGHT.' name_parts{2}]);

A = {'Version',ROIheader.Version;
     'Name', [ROIheader.Name '__RIGHT'];
     'Description','ROI_RIGHT';
     'Location',ROIheader.Location;
     'Date',ROIheader.Date;
     'Coordinate system','LL';
     'Unit','DEG';
     'UTM Zone',zone};
xlswrite(output_filename, A, 'A1:B8');

xlswrite(output_filename, {'UTM East, m','UTM North, m','Height, m', 'ROI id'}, 'A10:D10');
xlswrite(output_filename, {'Longitude','Latitude','Elevation, m', 'ROI id'}, 'A10:D10');

% Export data
A = cell(length(ROIs)*4,4);
for i = 1:length(ROIs)   
    
    [lat,lon] = minvtran(mstruct, ROIs_right_corners(i,1,1),ROIs_right_corners(i,1,2));
    A{(i-1)*4+1,1} = lon;
    A{(i-1)*4+1,2} = lat;
    A{(i-1)*4+1,3} = NaN;
    A{(i-1)*4+1,4} = ROIs(i).name{1};
    
    [lat,lon] = minvtran(mstruct, ROIs_right_corners(i,2,1),ROIs_right_corners(i,2,2));
    A{(i-1)*4+2,1} = lon;
    A{(i-1)*4+2,2} = lat;
    A{(i-1)*4+2,3} = NaN;
    A{(i-1)*4+2,4} = ROIs(i).name{1};
    
    [lat,lon] = minvtran(mstruct, ROIs_right_corners(i,3,1),ROIs_right_corners(i,3,2));
    A{(i-1)*4+3,1} = lon;
    A{(i-1)*4+3,2} = lat;
    A{(i-1)*4+3,3} = NaN;
    A{(i-1)*4+3,4} = ROIs(i).name{1};
    
    [lat,lon] = minvtran(mstruct, ROIs_right_corners(i,4,1),ROIs_right_corners(i,4,2));
    A{(i-1)*4+4,1} = lon;
    A{(i-1)*4+4,2} = lat;
    A{(i-1)*4+4,3} = NaN;
    A{(i-1)*4+4,4} = ROIs(i).name{1};
end

xlswrite(output_filename, A, ['A11:D' num2str(size(A,1)+10)]);

%% Export to xlsx (LEFT)
name_parts = strsplit(xlsROIfile,'.');
output_filename = fullfile(xlsROIfolder, [name_parts{1} '__LEFT.' name_parts{2}]);

A = {'Version',ROIheader.Version;
     'Name', [ROIheader.Name '__LEFT'];
     'Description','ROI_LEFT';
     'Location',ROIheader.Location;
     'Date',ROIheader.Date;
     'Coordinate system','LL';
     'Unit','DEG';
     'UTM Zone',zone};
xlswrite(output_filename, A, 'A1:B8');

xlswrite(output_filename, {'UTM East, m','UTM North, m','Height, m', 'ROI id'}, 'A10:D10');
xlswrite(output_filename, {'Longitude','Latitude','Elevation, m', 'ROI id'}, 'A10:D10');

% Export data
A = cell(length(ROIs)*4,4);
for i = 1:length(ROIs)   
    
    [lat,lon] = minvtran(mstruct, ROIs_left_corners(i,1,1),ROIs_left_corners(i,1,2));
    A{(i-1)*4+1,1} = lon;
    A{(i-1)*4+1,2} = lat;
    A{(i-1)*4+1,3} = NaN;
    A{(i-1)*4+1,4} = ROIs(i).name{1};
    
    [lat,lon] = minvtran(mstruct, ROIs_left_corners(i,2,1),ROIs_left_corners(i,2,2));
    A{(i-1)*4+2,1} = lon;
    A{(i-1)*4+2,2} = lat;
    A{(i-1)*4+2,3} = NaN;
    A{(i-1)*4+2,4} = ROIs(i).name{1};
    
    [lat,lon] = minvtran(mstruct, ROIs_left_corners(i,3,1),ROIs_left_corners(i,3,2));
    A{(i-1)*4+3,1} = lon;
    A{(i-1)*4+3,2} = lat;
    A{(i-1)*4+3,3} = NaN;
    A{(i-1)*4+3,4} = ROIs(i).name{1};
    
    [lat,lon] = minvtran(mstruct, ROIs_left_corners(i,4,1),ROIs_left_corners(i,4,2));
    A{(i-1)*4+4,1} = lon;
    A{(i-1)*4+4,2} = lat;
    A{(i-1)*4+4,3} = NaN;
    A{(i-1)*4+4,4} = ROIs(i).name{1};
end

xlswrite(output_filename, A, ['A11:D' num2str(size(A,1)+10)]);

%%

figure;
hold on;
for i = 1:length(ROIs)
    h1 = plot(ROIs(i).E, ROIs(i).N,'color',[0 1 0]);
end
h2 = plot(ROIs_right_corners(:,:,1)', ROIs_right_corners(:,:,2)','color',[1 0 0]);
h3 = plot(ROIs_left_corners(:,:,1)', ROIs_left_corners(:,:,2)','color',[0 0 1]);
legend([h1(1), h2(1), h3(1)],{'Plots','"Right"','"Left"'},'Location','EastOutside')

axis equal;