function exportMarkers( filename, markers)
%WRITE Summary of this function goes here
%   Detailed explanation goes here

    fid = fopen(filename,'w');
    validMarkers = markers([markers.isMarker]);
    for i = 1:length(validMarkers)
        [~, filename, ~] = fileparts(validMarkers(i).imageName);
            
        fprintf(fid, '%s,GCP_%s,%.3f,%.3f\r\n', ...
                filename, ...
                validMarkers(i).name, ...
                validMarkers(i).XY(1), ...
                validMarkers(i).XY(2));
    end
    fclose(fid);

end
