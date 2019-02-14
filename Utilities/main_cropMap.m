clearvars;
close all;

%%
addpath(genpath('../common/'));

%% Select map

disp('Select geotiff map...');
[fileName, pathName] = uigetfile({'*.tif','*.tiff'},'Select geotiff map');
fileNamePath = fullfile(pathName, fileName);
disp('Map selected:');
disp(['   File name: ' fileName]);
disp(['   Folder:    ' pathName]);

%% Select crop polygon file

[polygonFileName, polygonPathName] = uigetfile(fullfile(pathName,'*.mat'),'Select mat-file with polygon');

if all(polygonFileName ~= 0) && all(polygonPathName ~= 0)
    polygon = load(fullfile(polygonPathName,polygonFileName));
    if isfield(polygon,'X') && isfield(polygon,'Y')
        X = polygon.X;
        Y = polygon.Y;
        disp(['Loaded polygon with ' num2str(length(X)) ' coordinates.']);
    else
        disp('Mat-file does not contain X- and Y-coordinates...');
    end
end

%% Load map

fWaitbar = waitbar(0.25,'Loading map...');
[mapRaster, mapRasterInfo] = geotiffread(fileNamePath);
mapInfo = geotiffinfo(fileNamePath);
mapMaxChanIdx = 1;
if (size(mapRaster,3) >= 3)
    mapMaxChanIdx = 3;
end

%%
if (~exist('fWaitbar','var'))
    fWaitbar = waitbar(0,'','WindowStyle','modal');
else
    if (~isvalid(fWaitbar))
        fWaitbar = waitbar(0,'','WindowStyle','modal');
    end
end
waitbar(0.5, fWaitbar, 'Copying map to outputmap...','WindowStyle','modal');
mapRasterCropped = mapRaster;
mapRasterCroppedInfo = mapRasterInfo;

waitbar(0.75, fWaitbar, 'Plot maps...','WindowStyle','modal');
fMaps = figure('Name','Crop map','WindowState','maximized');
ax1 = subplot(1,2,1);
hMap1 = mapshow(im2double(mapRaster(:,:,1:mapMaxChanIdx)), mapRasterInfo);
if (size(mapRaster,3) > mapMaxChanIdx)
    set(hMap1,'AlphaData',mapRaster(:,:,mapMaxChanIdx+1))
end
title('Input map');
xlabel([upper(mapRasterInfo.RowsStartFrom(1)) lower(mapRasterInfo.RowsStartFrom(2:end))])
ylabel([upper(mapRasterInfo.ColumnsStartFrom(1)) lower(mapRasterInfo.ColumnsStartFrom(2:end))])
hold on;
ax2 = subplot(1,2,2);
hMap2 = mapshow(im2double(mapRasterCropped(:,:,1:mapMaxChanIdx)), mapRasterCroppedInfo);
if (size(mapRasterCropped,3) > mapMaxChanIdx)
    set(hMap2,'AlphaData',mapRasterCropped(:,:,mapMaxChanIdx+1))
end
title('Output map');
xlabel([upper(mapRasterCroppedInfo.RowsStartFrom(1)) lower(mapRasterCroppedInfo.RowsStartFrom(2:end))])
ylabel([upper(mapRasterCroppedInfo.ColumnsStartFrom(1)) lower(mapRasterCroppedInfo.ColumnsStartFrom(2:end))])
hold on;
drawnow;

waitbar(1, fWaitbar, 'Ready for user interaction','WindowStyle','modal');
pause(0.25);
close(fWaitbar);

button = 0;
updateLines = true;
while(~isempty(button))
    if (updateLines)
        updateLines = false;
        ch = get(ax1,'Children');
        for c = 1:length(ch)
            if isa(ch(c),'matlab.graphics.chart.primitive.Line')
                delete(ch(c));
            end
        end
        if (exist('X','var'))
            if(length(X) > 0)
                plot(ax1,[X X(1)],[Y Y(1)],'-o','Color',[1 1 1],'LineWidth',2);
                plot(ax1,[X X(1)],[Y Y(1)],'-o','Color',[1 0 0],'LineWidth',1);
            end
        end
    end
    
    [x,y,button] = ginput(1);
    thisAxes = gca;
    
    if (button == 1) % Left mouse button
        % Add point to polygon
        if (thisAxes == ax1)
            if (~exist('X','var'))
                X = x;
                Y = y;
            else
                X(end+1) = x;
                Y(end+1) = y;
            end
            updateLines = true;
        end
    elseif (button == 2) % Shift+mouse button or middle mouse button
        % Move neasest point on polygon
        if (thisAxes == ax1)
            if (length(X) > 0)
                [minDist,minDistIdx] = min(pdist2([X' Y'],[x y]));
                X(minDistIdx) = x;
                Y(minDistIdx) = y;
                updateLines = true;
            end
        end
    elseif (button == 3) % Right mouse button
        % Remove nearest point in polygon
        if (thisAxes == ax1)
            if (length(X) > 0)
                [minDist,minDistIdx] = min(pdist2([X' Y'],[x y]));
                X(minDistIdx) = [];
                Y(minDistIdx) = [];
                updateLines = true;
            end
        end
    elseif (button == 32) % Space button
        % Update map crop
        if (length(X) > 2)
            fWaitbar = waitbar(0.5,'Cropping map. Please wait...');
            [ mapRasterCropped, mapRasterCroppedMask, mapRasterCroppedInfo, ~] = mapcrop( mapRaster, mapRasterInfo, X, Y, 'native' );
            cla(ax2);
            hMap2 = mapshow(ax2, im2double(mapRasterCropped(:,:,1:mapMaxChanIdx)), mapRasterCroppedInfo);
            if (size(mapRasterCropped,3) > mapMaxChanIdx)
                set(hMap2,'AlphaData',mapRasterCroppedMask)
            end
            close(fWaitbar);
        end
    end
    disp(num2str([x,y,button],' %i'));
end
close(fMaps)

fWaitbar = waitbar(0.5,'Saving cropped map...');
[path,filename,ext] = fileparts(fileNamePath);
outputFilePath = fullfile(path, [filename '_cropped' ext]);
% geotiffwrite(outputFilePath,mapRasterCropped,mapRasterCroppedInfo);
GeoKeyDirectoryTag = mapInfo.GeoTIFFTags.GeoKeyDirectoryTag;
saveGeotiffWithMask( outputFilePath, mapRasterCropped, mapRasterCroppedMask, mapRasterCroppedInfo, GeoKeyDirectoryTag,'saveAsPseudoColor',false);

waitbar(0.75,fWaitbar,'Saving polygon...');
save(fullfile(path, [filename '_polygon.mat']),'X','Y');

close(fWaitbar);

disp('Done');