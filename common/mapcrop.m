function [ mapOut, mapOutMask, mapRasterRefOut, mapRect ] = mapcrop( mapIn, mapRasterRefIn, X, Y, maskType )
%MAPCROP crops a georeferenced image/map
% Mapcrop crops a georeferenced image/map to the smallest map containing
% a specified polygon.
%
% USAGE:
%   [ mapOut, mapOutMask, mapRasterRefOut, mapRect ] = mapcrop( mapIn, mapRasterRefIn, X, Y, maskType )
%
% INPUTS:
%   mapIn           : Image (grayscale or RGB). See geotiffread
%   mapRasterRefIn  : Map raster reference. See geotiffread and geotiffinfo
%   X               : Vector of X-coordinates of polygon. Must be in world coordinates.
%   Y               : Vector of Y-coordinates of polygon. Must be in world coordinates.
%   maskType        : Method used for determinig the mask. 'native' (default; see
%                     poly2mask) or 'weighted' (see poly2weightedmask).
%
% OUTPUTS:
%   mapOut          : Cropped map. Same type as mapIn.
%   mapOutMask      : Mask indicating which pixels in mapOut are within the
%                     polygon specified by X and Y. Same size as mapOut.
%   mapRasterRefOut : Map raster reference for mapOut.
%   mapRect         : 1x4 vector describing the coordiates and size of mapOut
%                     with respect to mapIn. Values are in pixel coordinates.
%                     See imcrop
%
% NOTES:
%   
% See also: geotiffread, geotiffinfo, imcrop

    if (nargin < 5)
        maskType = 'native';
    end


    roundingPrecision = 0.001;

    % Convert world coordinates to pixel coordinates
    [xPi, yPi] = mapRasterRefIn.worldToIntrinsic(X, Y);
%     [yP, xP] = mapRasterRefIn.worldToDiscrete(X, Y);
%     xP = round(xP);
%     yP = round(yP);

    % Convert from intrinsics to array indices
    xP = xPi - mapRasterRefIn.XIntrinsicLimits(1);
    yP = yPi - mapRasterRefIn.YIntrinsicLimits(1);
    
%     xPr = round(xP);
%     yPr = round(yP);

    xRect = [rounda(xP,roundingPrecision) rounda(xP,1-roundingPrecision)];
    yRect = [rounda(yP,roundingPrecision) rounda(yP,1-roundingPrecision)];
%     xRoundIdx = abs(xP - round(xP)) < roundingPrecision;
%     xP(xRoundIdx) = xPr(xRoundIdx);
%     yRoundIdx = abs(yP - round(yP)) < roundingPrecision;
%     yP(yRoundIdx) = yPr(yRoundIdx);
    
    % Define rectangle for cropping
    mapRect = poly2rect(xRect, yRect);
    
%     mapRect(1:2) = ceil(mapRect(1:2));
%     mapRect(3:4) = round(mapRect(3:4));
    
    % Allocate memory for cropped map
    mapOut = zeros(mapRect(4),mapRect(3),size(mapIn,3),class(mapIn));
    
    % Copy cropped map from original map pixel by pixel
    try
        for j = 1:mapRect(3)
            mapOut(1:mapRect(4),j,:) = mapIn(mapRect(2)+(1:mapRect(4)),mapRect(1)+j,:);
%             for i = 1:mapRect(4)
%                 mapOut(i,j,:) = mapIn(mapRect(2)+i,mapRect(1)+j,:);
%             end
        end
    catch ME
        disp(size(mapIn));
        disp(size(mapOut));
        disp(mapRect);
        disp([i j]);
        rethrow(ME)
    end
    
%     % Crop each channel and store in cell array
%     mapOutCell = cell(1,size(mapIn,3));
%     for i = 1:size(mapIn,3)
% 
%         % Extract cut rectangle of interest
%         mapOutCell{i} = imcrop(mapIn(:,:,i), mapRect);
%     end;
%     
%     % Reshape output map
%     mapOut = reshape(cell2mat(mapOutCell), size(mapOutCell{1},1), size(mapOutCell{1},2), []);
    
    
%     mapOutMask = poly2mask(round([xP(:); xP(1)] - mapRect(1)+0.5), round([yP(:); yP(1)] - mapRect(2) + 0.5), mapRect(4), mapRect(3));
    if (strcmp(maskType,'native'))
        mapOutMask = poly2mask([xP(:); xP(1)] - mapRect(1)+0.5, [yP(:); yP(1)] - mapRect(2) + 0.5, mapRect(4), mapRect(3));
    elseif (strcmp(maskType,'weighted'))
        mapOutMask = poly2weightedmask([xP(:); xP(1)] - mapRect(1)+0.5, [yP(:); yP(1)] - mapRect(2) + 0.5, mapRect(4), mapRect(3));
    else
        error('Unknown mask type!');
    end

    % Create raster reference for output map
    [utmX, utmY] = mapRasterRefIn.intrinsicToWorld(mapRect(1)+mapRasterRefIn.XIntrinsicLimits(1)+[0 mapRect(3)], mapRect(2)+mapRasterRefIn.YIntrinsicLimits(1)+[0 mapRect(4)]);
    mapRasterRefOut = mapRasterRefIn;
    mapRasterRefOut.XWorldLimits = sort(utmX, 'ascend');
    mapRasterRefOut.YWorldLimits = sort(utmY, 'ascend');
    mapRasterRefOut.RasterSize = [size(mapOut,1) size(mapOut,2)];
end