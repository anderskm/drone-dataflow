function [ ROIs] = extractROIsFromMap( map, mapInfo, ROIs, varargin )
%EXTRACTROISFROMMAP Summary of this function goes here
%   Detailed explanation goes here
%     mapTrans = mapInfo.SpatialRef;
    
    % Parse inputs
    p = parseInputs(varargin{:});
%     featureNames = p.Results.featureNames;
%     if (isempty(featureNames))
%         warning('Feature names not specified. Using feature handles as feature names.');
%         featureNames = cellfun(@func2str,featureHandles,'UniformOutput',false);
%     end;
%     if (length(featureNames) ~= length(featureHandles))
%         error('The number of feature names does not match the number of feature handles.');
%     end;
%     refMap = p.Results.refMap;
%     refMapInfo = p.Results.refMapInfo;
    newMapRasterRef = p.Results.newMapRasterRef;
%     edges = p.Results.edges;
    verbose = p.Results.verbose;
    numDisplaySpaces = (verbose-1)*3;
    
%     % If refMap is set, remap refMap into map coordinates and subtract it
%     % from map
%     if (~isempty(refMap))
%         if (isempty(refMapInfo))
%             error('Geotiff Info for reference map not set. Please set the input variable "refMapProj" and function geotiffread().');
%         end;
%         refMapTrans = refMapInfo.SpatialRef;
%         % Remap reference map into map coordinate system
%         if (verbose)
%             dispts('Remapping reference map into map coordinate system.', numDisplaySpaces);
%         end;
%         refMapRemapped = remapmap(refMap, refMapTrans, mapTrans, size(map), class(map));
%         
%         % Subtract reference map from map
%         if (verbose)
%             dispts('Subtracting reference map from map.', numDisplaySpaces);
%         end;
%         mapDiff = map - refMapRemapped;
%     end;

    if (verbose)
        dispts('Extracting ROIs from map...', numDisplaySpaces);
    end;
    progBar = ProgressBar(length(ROIs), 'Title','Extracting ROIs from map', 'UpdateRate', 1, 'UseUnicode', false);
    for r = 1:length(ROIs)
        ROI = ROIs(r);
%         if (verbose)
%             dispts(['ROI (' num2str(r) '/' num2str(length(ROIs)) '): ' ROI.name{1}] , numDisplaySpaces);
%         end;
        
        mstruct = geotiff2mstruct(mapInfo);
        [X, Y, Z] = mfwdtran(mstruct, ROI.latitude, ROI.longitude, ROI.altitude);
%         X = ROI.X;
%         Y = ROI.Y;
        try
            % Extract neighbourhood (50 * GSD)
            [X2,Y2] = polygrow(X,Y, mapInfo.SpatialRef.CellExtentInWorldX*50);
            [MapNeighborhood, MapMaskNeighborhood, mapROIrasterRefNeighborhood, ~] = mapcrop(map, mapInfo.SpatialRef, X2, Y2);

            if (~isempty(newMapRasterRef))
                % Map neihgbourhood into same raster coordinate system as
                % new map raster reference
                MapNeighbourhoodRemapped = remapmap(MapNeighborhood, mapROIrasterRefNeighborhood, ROIs(r).mapROIrasterRefNeighborhood); %, size(MapNeighborHood), class(MapNeighborHood));

                % Extract ROI
                [ Iroi, Imask, mapTransformationROI, ~ ] = mapcrop( MapNeighbourhoodRemapped, ROIs(r).mapROIrasterRefNeighborhood, X, Y );
            else
                [ Iroi, Imask, mapTransformationROI, ~ ] = mapcrop( MapNeighborhood, mapROIrasterRefNeighborhood, X, Y );
            end
        catch ME
            progBar.release()
            ProgressBar.deleteAllTimers();
            warnStruct = warning;
            warning on;
            warning(['Could not extract ROI (Name: ' ROI.name{1} ') from map.']);
            warning(warnStruct);
            rethrow(ME)
        end
        
%         % TESTING: REMOVE!!!
%         Iroi = MapNeighborhood;
%         Imask = MapMaskNeighborhood;
%         mapTransformationROI = mapROIrasterRefNeighborhood;
        
        tic;
        % Estimate local bias
%         disp('Estimate local bias...');
        xWorld = linspace(mapROIrasterRefNeighborhood.XWorldLimits(1),mapROIrasterRefNeighborhood.XWorldLimits(2),mapROIrasterRefNeighborhood.RasterSize(2));
        yWorld = linspace(mapROIrasterRefNeighborhood.YWorldLimits(1),mapROIrasterRefNeighborhood.YWorldLimits(2),mapROIrasterRefNeighborhood.RasterSize(1));
        [XWorld, YWorld] = meshgrid(xWorld, yWorld);
        localBiasMask = ones(size(XWorld),'logical');
        mstruct = geotiff2mstruct(mapInfo);
        for l = 1:length(ROIs)
            [XRoi, YRoi, ~] = mfwdtran(mstruct, ROIs(l).latitude, ROIs(l).longitude, ROIs(l).altitude);
            localBiasRoi = inpolygon(XWorld,YWorld,XRoi,YRoi);
            localBiasMask = and(localBiasMask, ~localBiasRoi);
%             clf(1)
%             imagesc(localBiasMask);
%             axis image;
%             drawnow;
        end
        localBias = median(MapNeighborhood(localBiasMask));
        
        % Store results
        ROIs(r).Iroi = Iroi;
        ROIs(r).Imask = Imask;
        ROIs(r).mapTransformationROI = mapTransformationROI;
        ROIs(r).MapNeighborhood = MapNeighborhood;
        ROIs(r).MapMaskNeighborhood = MapMaskNeighborhood;
        ROIs(r).mapROIrasterRefNeighborhood = mapROIrasterRefNeighborhood;
        ROIs(r).localBias = localBias;
        
        progBar([],[],[]);
    end
    progBar.release();
    
    if (verbose)
        dispts('ROIs extracted!', numDisplaySpaces);
    end

end

function p = parseInputs(varargin)
    p = inputParser();
%     addParameter(p,'featureNames',[],@(x)validateattributes(x, {'cell'},{'nonempty'}));
%     addParameter(p,'refMap',[]);
%     addParameter(p,'refMapInfo',[]);
    addParameter(p,'newMapRasterRef',[]);
    addParameter(p,'verbose',0,@(x)validateattributes(x, {'logical','numeric'},{'nonempty'}));
%     addParameter(p,'edges',0,@(x)validateattributes(x, {'numeric'},{'nonempty'}));
    parse(p, varargin{:}); 
end