function [ markers ] = readMarkerID(  I, markers, settings )
%READMARKERID Summary of this function goes here
%   Detailed explanation goes here

%     if (nargin < 3)
%         numBits = 3;
%     end;
%     if (nargin < 4)
%         bitsPadding = 1;
%     end;
    
    numBits = settings.markerDesign.numBits;
    bitsPadding = settings.markerDesign.bitMargin;

    relativeRadius = settings.markerDesign.relativeRadius;
    relativeCornerSize = 1 - 2*relativeRadius;
    relativeBitSize = 2*relativeRadius/(numBits + 2*bitsPadding);

    relativeSamplePoints = [0 relativeCornerSize/2 + relativeBitSize/2 + relativeBitSize*(1:numBits) 1];

    for m = 1:length(markers)
        X = markers(m).cornersXY([1 4],1);
        Y = markers(m).cornersXY([1 4],2);

        dist = sqrt(sum((X(1)-X(2))^2+(Y(1)-Y(2))^2));

        Mx = (Y(2)-Y(1))/(X(2)-X(1));
        My = (X(2)-X(1))/(Y(2)-Y(1));
        Cx = mean(Y-Mx*X);
        Cy = mean(X-My*Y);

        if (isinf(Mx))
%             y = linspace(Y(1),Y(2),26);
%             y = Y(1)+dist*relativeSamplePoints;
            y = Y(1) + (Y(2)-Y(1))*relativeSamplePoints;
            x = My*y+Cy;
        else
%             x = linspace(X(1),X(2),26);
            x = X(1)+dist*relativeSamplePoints;
            x = X(1) + (X(2)-X(1))*relativeSamplePoints;
            y = Mx*x+Cx;
        end;

        %      I = (I-minVal)./(maxVal - minVal);

        linePattern = interp2(I,x,y,'cubic');

        linePattern = (linePattern - linePattern(end))./(linePattern(1) - linePattern(end));

        markerID = bin2dec(num2str(linePattern(2:end-1) > 0.5));
        
        markers(m).ID = markerID;
        
    end;
    

end
