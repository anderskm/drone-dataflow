clearvars
% close all

ROIlinewidth = 1; % Line width (in px) used when plotting ROIs. Increase if, the are hard to see.

%%
addpath(genpath('../common'));

%% Select map

[mapFile, mapPath] = uigetfile('*.tif','Select map (geotif)');
mapFilePath = fullfile(mapPath, mapFile);

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

%% Load geotif

disp('Loading geotiff...');
[map, mapRasterInfo] = geotiffread(mapFilePath);
[mapInfo] = geotiffinfo(mapFilePath);
if (isa(map,'single'))
    map = double(map);
end
if (size(map,3) == 1)
    chns = 1;
elseif (size(map,3) == 2)
    chns = 1;
elseif (size(map,3) == 3)
    chns = 1:3;
elseif (size(map,3) == 4)
    chns = 1:3;
else
    chns = 1;
end
disp('Loading geotiff completed!');

%% Convert ROIs to UTM coordinates

mstruct = geotiff2mstruct(mapInfo);
for r = 1:length(ROIs)
    ROI = ROIs(r);
    [X, Y, Z] = mfwdtran(mstruct, ROI.latitude, ROI.longitude, ROI.altitude);
    ROIs(r).X = X;
    ROIs(r).Y = Y;
    ROIs(r).Z = Z;
end

%% Plot
disp('Displaying map...');
figure;
mapshow(map(:,:,chns), mapRasterInfo)
xlabel('UTM East, m');
ylabel('UTM North, m');
title(['Map: ' mapFile],'Interpreter','none');
disp('Plotting ROIs on map...');
hold on;
cmap = lines(length(ROIs));
for r = 1:length(ROIs)
    X = ROIs(r).X;
    Y = ROIs(r).Y;
    plot([X X(1)],[Y Y(1)],'-','color',[1 1 1],'LineWidth',ROIlinewidth+1);
    plot([X X(1)],[Y Y(1)],'-','color',cmap(r,:),'LineWidth',ROIlinewidth);
    text(mean(X),mean(Y),ROIs(r).name,'VerticalAlignment','middle','HorizontalAlignment','center','Background',cmap(r,:),'Rotation',30, 'FontSize',8,'Interpreter','none');
end
axis equal
disp('Done!');