function dispMarkerSummary( markers )
%DISPMARKERSUMMARY Summary of this function goes here
%   Detailed explanation goes here

    markerIDs = unique([markers.ID]);

    disp(['   Markers accepted/detected: '])
    for i = 1:length(markerIDs)
        theseMarkers = markers([markers.ID] == markerIDs(i));
        disp(['      GCP' num2str(markerIDs(i),'%03.0f') ': ' sprintf('% 3d',length(theseMarkers([theseMarkers.isMarker]))) '/' num2str(length(theseMarkers))])
    end
    disp(['   Total: ' num2str(length(markers([markers.isMarker]))) '/' num2str(length(markers))]);

end
