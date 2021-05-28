function [ ROIs ] = extractROIsFromGeotiff( mapFilePath, ROIs, ROIheader, varargin)
%EXTRACTROISFROMMAP Summary of this function goes here
%   Detailed explanation goes here

    p = parseInputs(varargin{:});
    refMapFile = p.Results.refMapFile;
    
    saveROIs = p.Results.saveROIs;
    ROIcolormap = p.Results.ROIcolormap;
    
    featureHandles = p.Results.featureHandles;
    featureNames = p.Results.featureNames;
    if (isempty(featureNames))
        warning('Feature names not specified. Using feature handles as feature names.');
        featureNames = cellfun(@func2str,featureHandles,'UniformOutput',false);
    end
    if (length(featureNames) ~= length(featureHandles))
        error('The number of feature names does not match the number of feature handles.');
    end
    edges = p.Results.edges;
    
    verbose = p.Results.verbose;
    numDisplaySpaces = (verbose-1)*3;
    
    % Check if all ROIs exist. If they do, don't load map and extract them again
    [mapPath,mapFilename,~] = fileparts(mapFilePath);
    [~, ROIfilename, ~] = fileparts(ROIheader.Source.File);
    ROImapsFolder = fullfile(mapPath, 'ROIs', ROIfilename);
    ROIs_exist = zeros(size(ROIs));
    for r = 1:length(ROIs)
        ROIfilename = fullfile(ROImapsFolder,'raw', [mapFilename '_ROI_' ROIs(r).name{1} '.tif']);
        ROIs_exist(r) = exist(ROIfilename, 'file');
    end
    
    if all(ROIs_exist) && isempty(refMapFile)
        dispts(['ROIs already extracted. Skip loading map, and loading extracted ROIs instead.'], numDisplaySpaces)
        saveROIs = false;
        tic;
        ROIsMap = ROIs;
        for r = 1:length(ROIs)
            ROIfilename = fullfile(ROImapsFolder,'raw', [mapFilename '_ROI_' ROIs(r).name{1} '.tif']);
            roi_info = geotiffinfo(ROIfilename);
            IroiGeotiff = geotiffread(ROIfilename);
            Iroi = IroiGeotiff(:,:,1:end-1);
            Imask = logical(IroiGeotiff(:,:,end));
            ROIsMap(r).Iroi = Iroi;
            ROIsMap(r).Imask = Imask;
            ROIsMap(r).mapTransformationROI = roi_info.SpatialRef;
        end
        clear roi_info IroiGeotiff Iroi Imask;
        toc
    else
        % Load map(s)
        if (verbose)
            dispts(['Loading map: ' mapFilePath], numDisplaySpaces);
        end
        [map, ~] = geotiffread(mapFilePath);
        [mapInfo] = geotiffinfo(mapFilePath);

        % Extracting ROIs from map
        if (verbose)
            dispts('Extracting ROIs from map...', numDisplaySpaces);
        end
    %     [ROIsMap] = extractROIsFromMap( map, mapInfo, ROIs, featureHandles, 'edges', edges, 'featureNames', featureNames, 'verbose', sign(verbose)*(verbose+1));
        [ROIsMap] = extractROIsFromMap( map, mapInfo, ROIs, 'verbose', sign(verbose)*(verbose+1));
        clear map;
    end
    
    % Load reference map
    if (isempty(refMapFile))
        mapRef = [];
        mapRefInfo = [];
    else
        if (verbose)
            dispts(['Loading reference map: ' refMapFile], numDisplaySpaces);
        end
        [mapRef, ~] = geotiffread(refMapFile);
        [mapRefInfo] = geotiffinfo(refMapFile);
        if (verbose)
            dispts('Extracting ROIs from reference map...', numDisplaySpaces);
        end
        [ROIsRefMap] = extractROIsFromMap( mapRef, mapRefInfo, ROIsMap, 'newMapRasterRef', mapInfo.SpatialRef, 'verbose', sign(verbose)*(verbose+1)); %, featureHandles, 'edges', edges, 'featureNames', featureNames, 'verbose', sign(verbose)*(verbose+1));
        clear mapRef;
        
        if (verbose)
            dispts('Subtracting ROIs from reference map from ROIs from map...', numDisplaySpaces);
        end
        for r = 1:length(ROIsMap)
            % Subtract local bias
            localBias = ROIsMap(r).localBias - ROIsRefMap(r).localBias;
%             disp(localBias);
%             figure;
%             subplot(2,3,1);
%             imagesc(ROIsMap(r).Iroi);
%             axis image;
%             colorbar;
%             subplot(2,3,4);
%             imagesc(ROIsMap(r).Imask);
%             axis image;
%             colorbar;
%             subplot(2,3,2);
%             imagesc(ROIsRefMap(r).Iroi);
%             axis image;
%             colorbar;
%             subplot(2,3,5);
%             imagesc(ROIsRefMap(r).Imask);
%             axis image;
%             colorbar;
            ROIsMap(r).Iroi = ROIsMap(r).Iroi - ROIsRefMap(r).Iroi; % - localBias;
%             subplot(2,3,3);
%             imagesc(ROIsMap(r).Iroi);
%             title(localBias)
%             axis image;
%             colorbar;
            ROIsMap(r).Imask = and(ROIsMap(r).Imask, ROIsRefMap(r).Imask);
%             subplot(2,3,6);
%             imagesc(ROIsMap(r).Imask);
%             axis image;
%             colorbar;
        end
    end
    
    if (verbose)
        dispts('Extracting features from ROIs...', numDisplaySpaces);
    end
    ROIs = extractFeaturesFromROIs( ROIsMap, featureHandles, featureNames, edges );
    
    
    % Save extracted ROIs as geotiffs
    if (saveROIs)
        if (verbose)
            dispts('Saving extracted ROIs...', numDisplaySpaces);
        end
        range = nan(1,2);
        if (ndims(ROIs(1).Iroi) == 2)
            % If only 2 dimensions, assume index map or similar
            range(1) = double(min(cellfun(@(x)min(x(:)),{ROIs.Iroi})));
            range(2) = double(max(cellfun(@(x)max(x(:)),{ROIs.Iroi})));
        elseif (ndims(ROIs(1).Iroi) > 2)
            if (size(ROIs(1).Iroi,3) == 2)
                % If the 3rd dimension has 2 channels, assume that the last
                % one is alpha for transparency and ignore it.
                range(1) = double(min(cellfun(@(x)min(min(x(:,:,1))),{ROIs.Iroi})));
                range(2) = double(max(cellfun(@(x)max(max(x(:,:,1))),{ROIs.Iroi})));
            elseif (size(ROIs(1).Iroi,3) == 3) 
                % If the 3rd dimension has 3 channels, assume RGB image.
%                 range(1) = double(min(cellfun(@(x)min(x(:)),{ROIs.Iroi})));
%                 range(2) = double(max(cellfun(@(x)max(x(:)),{ROIs.Iroi})));
            else
                % If 
%                 error('Unknown dimensions of ROIs. size(Iroi) = []');
            end
        else

        end
        
        
        % Create subdirectory for ROIs
        [mapPath,mapFilename,~] = fileparts(mapFilePath);
        [~, ROIfilename, ~] = fileparts(ROIheader.Source.File);
        ROImapsFolder = fullfile(mapPath, 'ROIs', ROIfilename);
        
        if (~exist(ROImapsFolder,'dir'))
            mkdir(ROImapsFolder);
        end
        if (~exist(fullfile(ROImapsFolder,'pseudo'),'dir'))
            mkdir(fullfile(ROImapsFolder,'pseudo'));
        end
        if (~exist(fullfile(ROImapsFolder,'raw'),'dir'))
            mkdir(fullfile(ROImapsFolder,'raw'));
        end

        % Get GeoKeyDirectoryTag from original map
        info = geotiffinfo(mapFilePath);
        GeoKeyDirectoryTag = info.GeoTIFFTags.GeoKeyDirectoryTag;
               
        % Loop throug ROIs
        for r = 1:length(ROIs)
            % Save ROIs as small geotiff
            ROIfilename = fullfile(ROImapsFolder,'pseudo', [mapFilename '_ROI_' ROIs(r).name{1} '.tif']);
            saveGeotiffWithMask( ROIfilename, ROIs(r).Iroi, ROIs(r).Imask, ROIs(r).mapTransformationROI, GeoKeyDirectoryTag,'Range',range,'saveAsPseudoColor',true);
            ROIfilename = fullfile(ROImapsFolder,'raw', [mapFilename '_ROI_' ROIs(r).name{1} '.tif']);
            saveGeotiffWithMask( ROIfilename, ROIs(r).Iroi, ROIs(r).Imask, ROIs(r).mapTransformationROI, GeoKeyDirectoryTag,'Range',range,'saveAsPseudoColor',false);
        end
        
        % Save legend
        if (~isempty(ROIcolormap))
            colorbarFilename = fullfile(ROImapsFolder, 'pseudo', [mapFilename '_colorbar.png']);
            saveColorbar( colorbarFilename, ROIcolormap, range );
        end
    end
    
    if (verbose)
        dispts('Map completed!', numDisplaySpaces);
    end
    
end

function p = parseInputs(varargin)
    p = inputParser();
    addParameter(p,'refMapFile','',@(x)validateattributes(x, {'string','char'},{'nonempty'}));
    addParameter(p,'saveROIs',true,@(x)validateattributes(x, {'logical'},{'nonempty'}));
    addParameter(p,'ROIcolormap',[]);
    addParameter(p,'featureHandles',{@(I,m)mean(I(m))},@(x)validateattributes(x, {'function_handle','cell'},{'nonempty'}));
    addParameter(p,'featureNames',[],@(x)validateattributes(x, {'cell'},{'nonempty'}));
    addParameter(p,'verbose',0,@(x)validateattributes(x, {'logical','numeric'},{'nonempty'}));
    addParameter(p,'edges',0,@(x)validateattributes(x, {'numeric'},{'nonempty'}));
    parse(p, varargin{:});
end