function [ markers, allMarkers ] = findMarkerCandidates(I, settings )
%FINDMARKERCANDIDATES Summary of this function goes here
%   Detailed explanation goes here

    kernel = settings.markerDetection.kernel;
    Npeaks = settings.markerDetection.numPeaks;
    suppressionRegion = settings.markerDetection.suppressionRegion;
    responseThreshold = settings.markerDetection.responseThreshold;
    
    
    suppressionRegion = floor(suppressionRegion/2)*2+1;
    
    % Normalize image
    I = (I-min(I(:)))/(max(I(:))-min(I(:)));

    % Convolve image with marker kernel
    response = conv2(I, kernel,'same');

    response(1:suppressionRegion(1),:) = 0;
    response(:,1:suppressionRegion(1)) = 0;
    response(end-suppressionRegion(1):end,:) = 0;
    response(:,end-suppressionRegion(1):end) = 0;
    
    % Find the peaks in the response
    resp = abs(response);
    resp(isnan(resp)) = 0;
    peaks = houghpeaks(round(100*(resp-min(resp(:)))./(max(resp(:)) - min(resp(:)))), Npeaks, 'NHoodSize', suppressionRegion);

    % Find the sub pixel position of the peaks
    [maxRowSub, maxColSub] = subpix2d(peaks(:,1), peaks(:,2), abs(response));
%     maxRowSub = peaks(:,1);
%     maxColSub = peaks(:,2);

    markers = struct([]);
    for i = 1:length(maxRowSub)
        markers(i).RowCol = [maxRowSub(i) maxColSub(i)];
        markers(i).XY = [maxColSub(i) maxRowSub(i)];
        markers(i).response = response(round(markers(i).RowCol(1)),round(markers(i).RowCol(2)));
    end;
    allMarkers = markers;
    if (~isempty(markers))
        markers(abs([markers.response]) < responseThreshold) = [];
    end;
end