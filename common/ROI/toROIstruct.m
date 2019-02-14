function [ ROIs ] = toROIstruct( longitude, latitude, altitude, ROIid )
%TOROISTRUCT Summary of this function goes here
%   Detailed explanation goes here

    utmStruct = defaultm('utm');
    utmStruct.zone = utmzone(mean(latitude),mean(longitude));
    utmStruct.geoid = wgs84Ellipsoid();
    utmStruct = defaultm(utmStruct);
    
%     [lat,lon,alt] = minvtran(utmStruct, x,y,z);

    uniqueROIids = unique(ROIid);

    ROIs = struct([]);
    for u = 1:length(uniqueROIids)
        idx = find(ismember(ROIid,uniqueROIids{u}));

        % Grab data points belonging to current ROI
        lon = longitude(idx);
        lat = latitude(idx);
        alt = altitude(idx);
        
        % Sort coordinates (counter clockwise)
        [theta, ~] = cart2pol(lon-mean(lon),lat-mean(lat));
        [~, sortIdx] = sort(theta);
        
        lon = lon(sortIdx)';
        lat = lat(sortIdx)';
        alt = alt(sortIdx)';
        
        % Estimate area
        [x,y,~] = mfwdtran(utmStruct, lat,lon,alt);
        area = polyarea(x,y);
        areaUnit = 'm^2';

        % Store coordinates in struct
        ROIs(u).name = uniqueROIids(u);
        ROIs(u).names = repmat(uniqueROIids(u),1,length(sortIdx));
        ROIs(u).type = 'polygon';
        ROIs(u).longitude = lon;
        ROIs(u).latitude = lat;
        ROIs(u).altitude = alt;
        ROIs(u).area = area;
        ROIs(u).areaUnit = areaUnit;
    end;

end

