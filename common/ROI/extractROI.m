function [ Iroi, Imask, mapTransformationROI ] = extractROI( map, mapInfo, ROI)
%EXTRACTCUT Summary of this function goes here
%   Detailed explanation goes here

    % Project longitude and latitude to map coordinates
    mstruct = geotiff2mstruct(mapInfo);
    [X, Y, Z] = mfwdtran(mstruct, ROI.latitude, ROI.longitude, ROI.altitude);
    ROI.X = X;
    ROI.Y = Y;
    ROI.Z = Z;
    
    % Convert cut to pixel coordinates
    mapTransformation = mapInfo.SpatialRef;
    [xP, yP] = mapTransformation.worldToIntrinsic(ROI.X, ROI.Y);
    
    % Define rectangle for cropping
    rect = poly2rect(xP, yP);
    rect(1:2) = floor(rect(1:2));
    rect(3:4) = ceil(rect(3:4))+1;
    
    % Loop through all image planes
    for i = 1:size(map,3)


%         if (nargin > 3)
%             p = zeros(3,length(xP));
%             for j = 1:length(xP)
%                 p(:,j) = [xP(j) yP(j) 1]';
%             end;
% 
%             p_prime_cart = H*p;
%             for j = 1:size(p_prime_cart,2)
%                 p_prime_cart(:,j) = p_prime_cart(:,j) / p_prime_cart(end,j);
%             end;
%             
%             xP = p_prime_cart(1,:)';
%             yP = p_prime_cart(2,:)';
%         end;
        
        % Determine rectangle of interest
%         rect = poly2rect(xP, yP) + [-1 -1 +1 +1];

        % Extract cut rectangle of interest
        I2{i} = imcrop(map(:,:,i), rect);
        
        % Find UTM coordinates of upper left corner pixel
%         [xW, yW] = pix2utm(TFW(i), rect(1), rect(2));
        
        
        % Update TFW struct
%         TFW(i).coordinate.x = xW;
%         TFW(i).coordinate.y = yW;
    end;
    
    Iroi = reshape(cell2mat(I2), size(I2{1},1), size(I2{1},2), []);

    Imask = poly2mask([xP(:); xP(1)]- rect(1), [yP(:); yP(1)]- rect(2), ceil(rect(4))+1, ceil(rect(3))+1);
    % Determine rectangle of interest
%     rect = poly2rect(xP, yP) + [-1 -1 +1 +1];

    [utmX, utmY] = mapTransformation.intrinsicToWorld([rect(1)-0.5 rect(1)+rect(3)+0.5], [rect(2)-0.5 rect(2)+rect(4)+0.5]);

    mapTransformationROI = mapTransformation;
    mapTransformationROI.XWorldLimits = sort(utmX, 'ascend');
    mapTransformationROI.YWorldLimits = sort(utmY, 'ascend');
    mapTransformationROI.RasterSize = [size(Iroi,1) size(Iroi,2)];

    % Extract cut rectangle of interest
%     Imask = imcrop(Imask, rect);
end

