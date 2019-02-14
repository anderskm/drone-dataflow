function [ markers, validMarkers, allMarkers ] = findMarkerCandidateCorners( I, markers, settings)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

    angularResolution = settings.markerCornerDetection.angularResolution;
    stdThreshold = settings.markerCornerDetection.stdThreshold;
    relativeRadius = settings.markerDesign.relativeRadius;
    diameter = settings.markerDetection.diameter;
    filterResponseThreshold = settings.markerCornerDetection.filterResponseThreshold;
    

%     searchMin = 0.9*diameter/0.7*sqrt(0.35^2*2);
%     searchMax = 1.1*diameter/0.7*sqrt(0.5^2*2);
%     searchRange = linspace(searchMin, searchMax, max(10, round(searchMax-searchMin+1)));
    

    
    searchMin = 0.9*diameter/0.7*sqrt(0.35^2*2);
    searchMax = 1.1*diameter/0.7*sqrt(0.5^2*2);
    searchRange = linspace(searchMin, searchMax, round(searchMax-searchMin+1));

%     searchRange
    
    validMarker = zeros(size(markers));
    for m = 1:length(markers)

        y0 = markers(m).RowCol(1);
        x0 = markers(m).RowCol(2);

        tau = 0:angularResolution:(360-angularResolution);
        polImg = zeros(length(searchRange),length(tau));
        for r = 1:length(searchRange);
            R = searchRange(r);
            x = x0+R.*cosd(tau);
            y = y0+R.*sind(tau);
            polImg(r,:) = interp2(I,x,y,'cubic');
        end;
        polImg(isnan(polImg)) = mean(polImg(:),'omitnan');
        polImg2 = (polImg -repmat(min(polImg,[],2),1,size(polImg,2)))./(repmat(max(polImg,[],2),1,size(polImg,2)) - repmat(min(polImg,[],2),1,size(polImg,2)));
        polImg = (polImg-min(polImg(:)))./(max(polImg(:))-min(polImg(:)));
        
        polImg = polImg2;
%         polImg = polImg*2-1;
        
        if (1 == 2) % Filter on angularPower
            angularPower = sum((polImg - mean(polImg(:))).^2,1);
            angularPower = angularPower - mean(angularPower);

            % Create match filter
            matchFilter = zeros(1,360/angularResolution);
            matchFilter([0 90 180]/angularResolution+1) = 1/4;
            matchFilter(270/angularResolution) = -1/4;

            % Find best matching angular response
            filterResponse = conv([angularPower, angularPower], fliplr(matchFilter),'valid');
            [~, maxFilterResponseIdx] = max(filterResponse);

            % Convert max response to corresponding angles
            cornerAnglesIdx = mod(maxFilterResponseIdx + [0 90 180]/angularResolution-1,360/angularResolution)+1;
            cornerAngles = tau(cornerAnglesIdx)';

            % Find the corresponding radius for each corner
    %         cornerRadii = median(searchRange)*ones(size(cornerAngles)); % Consider using a smarter method than just the median search range. Perhaps do a line search for max val at angle or similar
            [~, searchRangeIdx] = max(polImg(:,cornerAnglesIdx));
            cornerRadii = searchRange(searchRangeIdx)';

            % Make sure that all three potential corners are larger than X
            % standard deviations
            isMarker = all(angularPower(cornerAnglesIdx) > (mean(angularPower)+stdThreshold*std(angularPower)));
            validMarker(m) = isMarker;
        else % Filter on polImg
            % Create match filter
%             matchFilter = zeros(1,360/angularResolution);
%             matchFilter([0 90 180]/angularResolution+1) = 1/3;
%             matchFilter(270/angularResolution) = -1;

            [matchFilter, blobSize] = createMatchFilter(diameter, relativeRadius, angularResolution);
            
            filterResponse = conv2([polImg polImg], fliplr(matchFilter),'valid');
            filterResponse = filterResponse(:,1:end-1);
            
            [maxFilterReponse, maxFilterResponseIdx] = max(filterResponse(:));
            [radiusMaxIdx, angleMaxIdx] = ind2sub(size(filterResponse),maxFilterResponseIdx);
            
            radiusMaxIdx = radiusMaxIdx + (blobSize(1)-1)/2;
            angleMaxIdx = angleMaxIdx + (blobSize(2)-1)/2;

            % Convert max response to corresponding angles
            cornerAnglesIdx = mod(angleMaxIdx + [0 90 180]/angularResolution-1,360/angularResolution)+1;
%             cornerAngles = tau(cornerAnglesIdx)';
            cornerAngles = interp1(1:(length(tau)*2),[tau 360+tau],cornerAnglesIdx);
            
%             [~, searchRangeIdx] = max(polImg(:,cornerAnglesIdx));
%             cornerRadii = searchRange(searchRangeIdx)';
            cornerRadii = mean(searchRange([floor(radiusMaxIdx) ceil(radiusMaxIdx)]))*ones(size(cornerAngles));
            
%             isMarker = all(polImg(radiusMaxIdx, round(cornerAnglesIdx)) > (mean(polImg(radiusMaxIdx,:))+stdThreshold*std(polImg(radiusMaxIdx,:))));
            isMarker = (maxFilterReponse-mean(filterResponse(:)))/std(filterResponse(:)) > filterResponseThreshold;
            validMarker(m) = isMarker;
%             validMarker(m) = 1;

            
        end;
        
        % Convert corner angles and radii to global image coordinates
        cornersX = x0+cornerRadii.*cosd(cornerAngles);
        cornersY = y0+cornerRadii.*sind(cornerAngles);
        
        % %%%%%%%%%%%%%%%%%%%%%%% %
        % Refine corner estimates %
        % %%%%%%%%%%%%%%%%%%%%%%% %
        
        % Find last corner
        cornerRadiusLast = mean(cornerRadii);
        cornerAngleLast = mean(mod(cornerAngles+[270 180 90],360));
        cornerAngles = [cornerAngles'; cornerAngleLast];
        cornerRadii = [cornerRadii'; cornerRadiusLast];
        
        cornersX = x0+cornerRadii.*cosd(cornerAngles);
        cornersY = y0+cornerRadii.*sind(cornerAngles);
        
%         cornerResponses = polImg([floor(radiusMaxIdx) ceil(radiusMaxIdx)], mod(round(cornerAnglesIdx),360));
        cornerResponses = polImg([floor(radiusMaxIdx) ceil(radiusMaxIdx)], mod([floor(cornerAnglesIdx-1) ceil(cornerAnglesIdx-1)],360)+1);
        cornerResponses = cornerResponses';
        cornerResponses = mean(reshape(cornerResponses(:), 3, [])',1);
        cornerResponseRadiusMean = mean(mean(polImg([floor(radiusMaxIdx) ceil(radiusMaxIdx)],:),1),2);
        cornerResponseRadiusStd = std(mean(polImg([floor(radiusMaxIdx) ceil(radiusMaxIdx)],:),1));
        
        cornerFilterResponseMax = maxFilterReponse;
        cornerFilterResponseMean = mean(filterResponse(:));
        cornerFilterResponseStd = std(filterResponse(:));
        
        if (isMarker)
            phaseAngle = angle(markers(m).response);
            markerCropSize = ceil(diameter/0.7*2);
            Imarker = imcrop(I, [x0-markerCropSize/2 y0-markerCropSize/2 markerCropSize markerCropSize]);
%             figure;
%             subplot(3,1,1);
% %                 imshow(Imarker);
%             imshow(I);
%             hold on;
%             viscircles(repmat([x0 y0],3,1), [diameter/2; searchMin; searchMax],'DrawBackgroundCircle',false,'LineWidth',1);
%             plot(x0, y0,'*r');
%             plot(cornersX, cornersY,'r.');
%             plot(cornersX(1), cornersY(1),'ro');
%             plot([x0 x0+diameter/2*cos(phaseAngle)], [y0 y0+diameter/2*sin(phaseAngle)],'-r');
%             axis([x0-markerCropSize/2 x0+markerCropSize/2 y0-markerCropSize/2 y0+markerCropSize/2]);
%             subplot(3,1,2);
%             imshow(polImg);
%             hold on;                
%             plot(cornerAnglesIdx, radiusMaxIdx*ones(size(cornerAnglesIdx)),'rx');
% %             title(num2str((polImg(radiusMaxIdx, round(cornerAnglesIdx))-mean(polImg(radiusMaxIdx,:)))./stdThreshold*std(polImg(radiusMaxIdx,:))));
%             title(num2str((cornerResponses-cornerResponseRadiusMean)./stdThreshold*cornerResponseRadiusStd));
%             subplot(3,1,3);
%             imagesc(filterResponse);
% %                 imshow(polImg);
%             hold on;
% %                 plot(angleMaxIdx, radiusMaxIdx,'rx');
%             title(num2str([cornerFilterResponseMax cornerFilterResponseMean cornerFilterResponseStd (cornerFilterResponseMax - cornerFilterResponseMean)/cornerFilterResponseStd]))
%                 pause;
        end;
        
        % Store results in marker
        markers(m).isMarker = isMarker;
        markers(m).cornerAngles = cornerAngles;
        markers(m).cornerRadii = cornerRadii;
        markers(m).cornersXY = [cornersX cornersY];
        markers(m).cornersRowCol = [cornersY cornersX];
        markers(m).ID = NaN;
        
        markers(m).cornerResponses = cornerResponses;
        markers(m).cornerResponseRadiusMean = cornerResponseRadiusMean;
        markers(m).cornerResponseRadiusStd = cornerResponseRadiusStd;
        
        markers(m).cornerFilterResponseMax = cornerFilterResponseMax;
        markers(m).cornerFilterResponseMean = cornerFilterResponseMean;
        markers(m).cornerFilterResponseStd = cornerFilterResponseStd;
    end;

    validMarkers = find(validMarker);
    allMarkers = markers;
    markers = markers(validMarkers);
end
