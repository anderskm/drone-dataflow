function [MAP1_2] = remapmap(map, mapTransOld, mapTransNew)

%     if (nargin < 5)
%         newMapClass = class(map);
%     end
%     
%     if (nargin < 4)
% %         XWorldLimits(1) = ceil((mapTransOld.XWorldLimits(1) - mapTransNew.XWorldLimits(1))/mapTransNew.CellExtentInWorldX)*mapTransNew.CellExtentInWorldX + mapTransNew.XWorldLimits(1);
% %         XWorldLimits(2) = floor((mapTransOld.XWorldLimits(2) - mapTransNew.XWorldLimits(2))/mapTransNew.CellExtentInWorldX)*mapTransNew.CellExtentInWorldX + mapTransNew.XWorldLimits(2);
% %         YWorldLimits(1) = ceil((mapTransOld.YWorldLimits(1) - mapTransNew.YWorldLimits(1))/mapTransNew.CellExtentInWorldY)*mapTransNew.CellExtentInWorldY + mapTransNew.YWorldLimits(1);
% %         YWorldLimits(2) = floor((mapTransOld.YWorldLimits(2) - mapTransNew.YWorldLimits(2))/mapTransNew.CellExtentInWorldY)*mapTransNew.CellExtentInWorldY + mapTransNew.YWorldLimits(2);
% %         RasterSize = round([(XWorldLimits(2)-XWorldLimits(1))/mapTransNew.CellExtentInWorldX (YWorldLimits(2)-YWorldLimits(1))/mapTransNew.CellExtentInWorldY]);
%         mapSizeNew = mapTransNew.RasterSize;
%     end

    mapSizeNew = mapTransNew.RasterSize;

    % Create mesh grid of image coordinates in new image coordinate system
    [X1, Y1] = meshgrid(1:mapSizeNew(2), 1:mapSizeNew(1));
    % Convert new image coordinates to world coordinates
    [xWorld, yWorld] = intrinsicToWorld(mapTransNew, X1(:), Y1(:));

    % Convert world coordinates to old image coordinates
    [X1_2, Y1_2] = worldToIntrinsic(mapTransOld, xWorld, yWorld);
%     % Create mesh grid on old image coordinates
    [X2, Y2] = meshgrid(1:size(map,2), 1:size(map,1));

%     map1_2 = zeros(size(xWorld), newMapClass);
%     for i = 1:mapSizeNew(2)
% %         timeLeft = toc/i*(mapSizeNew(1)-i);
% %         newString = ['(' num2str(i) '/' num2str(mapSizeNew(1)) ') Time left: ' sec2dhms(timeLeft)];
% %         disp(newString);
%         
%         % Get linear indes of query coordinates
%         idx = (i-1)*mapSizeNew(1) + (1:mapSizeNew(1));
%         % Make sure that the query coordinates are within old image
%         % boundaries. If not, use boundry
%         X1_2_tmp = max(min(round(X1_2(idx)), size(map,2)),1);
%         Y1_2_tmp = max(min(round(Y1_2(idx)), size(map,1)),1);
%         % Convert new coordinates to linear indices
%         linearIdx = sub2ind(size(map), Y1_2_tmp, X1_2_tmp);
%         % Copy old map to new map
%         map1_2(idx) = map(linearIdx);
%         
%         % MATLAB built-in interp2 is too slow
% %         map1_2(idx) = interp2(X2, Y2, map(1:end,1:end), X1_2(idx), Y1_2(idx),'linear');
%     end;
    
    map1_2 = interp2(X2, Y2, map(1:end,1:end), X1_2, Y1_2, 'linear');

    % Reshape map from 1D shape to 2D shape
    MAP1_2 = reshape(map1_2, floor(mapSizeNew(1)), floor(mapSizeNew(2)));
end