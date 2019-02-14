function [ ROIs ] = loadROIcsv( ROIfile )
%LOADROICSV Summary of this function goes here
%   Detailed explanation goes here

    fid = fopen(ROIfile);
    try
        data = textscan(fid, '%s%f%f%f','Delimiter',',');
    catch ex
        fclose(fid);
        rethrow(ex);
    end
    fclose(fid);
    
    ROIid = data{1,1};
    utmEast = data{1,2};
    utmNorth = data{1,3};
    height = data{1,3};


    uniqueROIids = unique(ROIid);

    ROIs = struct([]);
    for u = 1:length(uniqueROIids)
        idx = find(ismember(ROIid,uniqueROIids{u}));

        X = utmEast(idx);
        Y = utmNorth(idx);
        H = height(idx);

        % Sort coordinates (counter clockwise)
        [theta, ~] = cart2pol(X-mean(X),Y-mean(Y));
        [~, sortIdx] = sort(theta);

        % Store coordinates in struct
        ROIs(u).name = uniqueROIids(u);
        ROIs(u).names = repmat(uniqueROIids(u),1,length(sortIdx));
        ROIs(u).type = 'polygon';
        ROIs(u).X = X(sortIdx)';
        ROIs(u).Y = Y(sortIdx)';
        ROIs(u).height = H(sortIdx)';
    end;
    
end

