function exportROIs2xls(xlsFilename, xlsSheet, ROIsExtracted)
%EXPORTROIS2XLS Summary of this function goes here
%   Detailed explanation goes here

    [headers, ROInames, featureMatrix] = ROIs2mats(ROIsExtracted);

    % Write headers
    xlswrite(xlsFilename, {'Specified edges (m)';'Applied edges (m)';'Feature handles'; 'ROI names\ Feature names'}, xlsSheet, 'A1:A4');
    xlswrite(xlsFilename, headers, xlsSheet, 'B1');
    
    % Write ROI names
    xlswrite(xlsFilename, ROInames, xlsSheet, 'A5');
    
    % Write features
    xlswrite(xlsFilename, featureMatrix, xlsSheet, 'B5');

end

function [headers, ROInames, dataMat] = ROIs2mats(ROIs)
    % Headers = edges specified, edges applied, feature names, feature functions
    numFeatures = size(ROIs(1).features,2);
    numEdges = size(ROIs(1).features,1);

    % Create header cell
    edgesSpecified = ROIs(1).edgesSpecified;
    edgesSpecified = reshape(repmat(edgesSpecified,numFeatures,1),1,[]);
    edgesSpecified = num2cell(edgesSpecified);
    edgesApplied = ROIs(1).edgesApplied;
    edgesApplied = reshape(repmat(edgesApplied,numFeatures,1),1,[]);
    edgesApplied = num2cell(edgesApplied);
    featureHandles = cellfun(@func2str,ROIs(1).featureHandles,'UniformOutput',false);
    featureHandles = repmat(featureHandles,1,numEdges);
    featureNames = ROIs(1).featureNames;
    featureNames = repmat(featureNames,1,numEdges);
    headers = [edgesSpecified; edgesApplied; featureHandles;featureNames];
    
    % Create ROI names
    ROInames = [ROIs.name]';
    
    % Create data matrix
    dataMat = NaN(length(ROIs), numFeatures*numEdges);
    for i = 1:length(ROIs)
        features = ROIs(i).features;
        dataMat(i,:) = reshape(features',numFeatures*numEdges,1)';
    end;
end
