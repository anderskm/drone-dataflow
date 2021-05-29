function [ ROIs ] = extractFeaturesFromROIs( ROIs, featureHandles, featureNames, edges )
%EXTRACTFEATURESFROMROIS Summary of this function goes here
%   Detailed explanation goes here

    % If no edges is specified, assume, that no edges should be removed
    if (nargin < 4)
        edges = 0;
    end
    
    global intermediate_results;

    % Loop over ROIs
    progBar = ProgressBar(length(ROIs), 'Title','Extracting features from ROIs', 'UpdateRate', 1, 'UseUnicode', false);
    for r = 1:length(ROIs)
        Iroi = ROIs(r).Iroi;
        Imask = ROIs(r).Imask;
        mapTransformationROI = ROIs(r).mapTransformationROI;
        
        features = zeros(length(edges), length(featureHandles));
        % Loop over edges
        for e = 1:length(edges)
            edge = edges(e);
            ImaskEroded = imerode(Imask, strel('disk',round(edge/mapTransformationROI.CellExtentInWorldX)));
            intermediate_results = struct();
            for f = 1:length(featureHandles)
                featureHandle = featureHandles{f};
%                 feature = featureHandle(Iroi, ImaskEroded, mapTransformationROI);
                feature = feval(featureHandle, Iroi, ImaskEroded, mapTransformationROI);
                if (isempty(feature))
                    feature = NaN;
                end
                features(e, f) = feature;
            end;
            struct_field_names = fieldnames(intermediate_results);
            intermediate_results = rmfield(intermediate_results, struct_field_names);
        end;
        
        % Calculate the actual size of the edges based on the ground
        % sampling distance
        edgesApplied = round(edges/mapTransformationROI.CellExtentInWorldX)*mapTransformationROI.CellExtentInWorldX;
        if (length(edgesApplied) ~= length(unique(edgesApplied)))
            warning('At least one pair of specified edges correspond to the same applied edges after quantization.');
        end;
        
        % Store results in ROI struct
        ROIs(r).features = features;
        ROIs(r).featureHandles = featureHandles;
        ROIs(r).featureNames = featureNames;
        ROIs(r).edgesApplied = edgesApplied;
        ROIs(r).edgesSpecified = edges;

        
        progBar([],[],[]);
    end
    progBar.release();

end
