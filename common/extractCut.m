function [ Icut, Imask, mapTransformationCut ] = extractCut( map, areas, mapTransformation )
%EXTRACTCUT Summary of this function goes here
%   Detailed explanation goes here

    for i = 1:size(map,3);
        
        % Convert cut to pixel coordinates
%         [xP, yP] = utm2pix(TFW(i), areas.X, areas.X);
        [xP, yP] = mapTransformation.worldToIntrinsic(areas.X, areas.Y);

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
        rect = poly2rect(xP, yP);
        rect(1:2) = floor(rect(1:2));
        rect(3:4) = ceil(rect(3:4))+1;
        % Extract cut rectangle of interest
        I2{i} = imcrop(map(:,:,i), rect);
        
        % Find UTM coordinates of upper left corner pixel
%         [xW, yW] = pix2utm(TFW(i), rect(1), rect(2));
        
        
        % Update TFW struct
%         TFW(i).coordinate.x = xW;
%         TFW(i).coordinate.y = yW;
    end;
    
    Icut = reshape(cell2mat(I2), size(I2{1},1), size(I2{1},2), []);

    Imask = poly2mask([xP; xP(1)]- rect(1), [yP; yP(1)]- rect(2), ceil(rect(4))+1, ceil(rect(3))+1);
    % Determine rectangle of interest
%     rect = poly2rect(xP, yP) + [-1 -1 +1 +1];

    [utmX, utmY] = mapTransformation.intrinsicToWorld([rect(1)-0.5 rect(1)+rect(3)+0.5], [rect(2)-0.5 rect(2)+rect(4)+0.5]);

    mapTransformationCut = mapTransformation;
    mapTransformationCut.XWorldLimits = sort(utmX, 'ascend');
    mapTransformationCut.YWorldLimits = sort(utmY, 'ascend');
    mapTransformationCut.RasterSize = [size(Icut,1) size(Icut,2)];

    % Extract cut rectangle of interest
%     Imask = imcrop(Imask, rect);
end

