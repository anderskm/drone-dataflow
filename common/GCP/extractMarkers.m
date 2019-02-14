function [markers] = extractMarkers(I, markers, settings)
%EXTRACTMARKERS Summary of this function goes here
%   Detailed explanation goes here

    for m = 1:length(markers);
        cornersRowCol = markers(m).cornersRowCol;
        R = cornersRowCol(:,1);
        C = cornersRowCol(:,2);
        Rmin = round(min(R));
        Rmax = round(max(R));
        
        Rmin = max(Rmin - round((Rmax-Rmin)/10),1);
        Rmax = min(Rmax + round((Rmax-Rmin)/10),size(I,1));
        
        Cmin = round(min(C));
        Cmax = floor(max(C));
        
        Cmin = max(Cmin - round((Cmax-Cmin)/10),1);
        Cmax = min(Cmax + round((Cmax-Cmin)/10),size(I,2));
        
        Imarker = I(Rmin:Rmax,Cmin:Cmax);
        theta = atan2d(R(4)-R(1),C(4)-C(1));
        ImarkerRotated = imrotate(Imarker, theta,'bilinear');
        markers(m).thumbnail.Image = Imarker;
        markers(m).thumbnail.ImageRotated = ImarkerRotated;
    end;

end
