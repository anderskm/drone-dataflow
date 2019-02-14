function [ fig ] = showROIs( longitude, latitude, height, ROIids, roiHeader, export )
%SHOWROISFOREXPORT Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 5)
        roiHeader = setROIheader( 'No name', 'No description', 'No location', datetime(0,'ConvertFrom','excel','Format','dd-MMM-yyyy'), mean(longitude), mean(latitude), mean(height), length(longitude));
    end
    if (nargin < 6)
        export = false;
    end

    fig = figure(gcf);
    clf;

    maximizeFigure();

    subplot(3,3,[1 2 4 5 7 8])
    plotROIpositions( longitude, latitude, ROIids, roiHeader);

    % Plot Denmark
    if (export)
        overviewSubplots = [3 6];
    else
        overviewSubplots = [3 6 9];
    end
    subplot(3,3,overviewSubplots)
    plotOverviewMap(roiHeader.Longitude, roiHeader.Latitude);

    if (export)
        % Add export button
        exportButtonHandle = uicontrol('Style', 'pushbutton', ...
                                       'String', 'Export to CSV',...
                                       'Units', 'normalized', ...
                                       'Position', [0.75 0.167 0.167 0.167],...
                                       'FontSize', 28, ...
                                       'Callback', {@exportROIsToCSVcallback, longitude, latitude, height, ROIids});
    end

end

function exportROIsToCSVcallback( src, event, longitude, latitude, height, ROIids )
%EXPORTROISTOCSV Summary of this function goes here
%   Detailed explanation goes here

    [FileName,PathName,FilterIndex] = uiputfile('ROIs.csv','Save ROIs as CSV');

    if (isnumeric(FileName))
        warning('ROI export to CSV cancelled by user!');
    else
%         [a,b,e2,finv] = refell('WSG84');
%         [utm]
        saveROIcsv(fullfile(PathName, FileName), utmEast, utmNorth, height, ROIids);
        msgbox({'ROIs have been saved to file:'; fullfile(PathName, FileName)},'ROIs saved')
    end

end