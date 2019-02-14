function [ markers, allMarkers ] = imageStruct2markersStruct( images )
%IMAGESTRUCT2MARKERSSTRUCT Summary of this function goes here
%   Detailed explanation goes here

    markers = [];
    for i = 1:length(images);
        if (~isempty(images(i).markers))
            if (isempty(markers));
                markers = images(i).markers;
            else
                markers = [markers images(i).markers];
            end;
        end;
    end;
    
    allMarkers = [];
    if (nargout > 1)
        for i = 1:length(images);
            if (~isempty(images(i).allMarkers))
                if (isempty(allMarkers));
                    allMarkers = images(i).allMarkers;
                else
                    allMarkers = [allMarkers images(i).allMarkers];
                end;
            end;
        end;
    end

end

