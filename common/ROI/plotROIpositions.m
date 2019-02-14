function plotROIpositions( longitude, latitude, ROIids, roiHeader, varargin)
%PLOTROIS Summary of this function goes here
%   Detailed explanation goes here

    % Parse optional name-value pairs
    p = inputParser; % Initiate parser
    addParameter(p,'Axis',gca); % Add default values to (optional) parameters
    addParameter(p,'Width',640);
    addParameter(p,'Height',480);
    addParameter(p,'Scale',2);
    addParameter(p,'Resize',1);
    addParameter(p,'MapType','satellite');
    addParameter(p,'Alpha',1);
    addParameter(p,'ShowLabels',1);
    addParameter(p,'Style','');
    addParameter(p,'Language','');
    addParameter(p,'Refresh',1);
    addParameter(p,'AutoAxis',1);
    addParameter(p,'FigureResizeUpdate',1);
    parse(p, varargin{:}); % Parse inputs

%     [latitude, longtitude] = utm2ell(utmNorth, utmEast, zone);
%     longtitude = longtitude/pi*180;
%     latitude = latitude/pi*180;

    uniqueROIids = unique(ROIids);

    cmap = lines(length(uniqueROIids));
    for i = 1:length(uniqueROIids)
        ROIidx = find(strcmp(ROIids,uniqueROIids{i}));
        lat = latitude(ROIidx);
        long = longitude(ROIidx);
        plot([long(:); long(1)], [lat(:); lat(1)],'-','Color',[1 1 1],'LineWidth',2);
        hold on;
    end
    for i = 1:length(uniqueROIids)
        ROIidx = find(strcmp(ROIids,uniqueROIids{i}));
        lat = latitude(ROIidx);
        long = longitude(ROIidx);
        plot([long(:); long(1)], [lat(:); lat(1)],'-','Color',cmap(i,:),'LineWidth',1);
        text(mean(long), mean(lat), uniqueROIids{i},'HorizontalAlign','center','VerticalAlign','middle','BackgroundColor',cmap(i,:),'Margin',0.1)
        hold on;
    end
    title({roiHeader.Name; [roiHeader.Location ', ' char(roiHeader.Date)];['ROI sizes: ' num2str(roiHeader.Area.mean,'%.2f') roiHeader.Area.unit ' +/- ' num2str(2*roiHeader.Area.std,'%.2f') roiHeader.Area.unit]},'Interpreter','none');
%     title({roiHeader.Name; roiHeader.Description; [roiHeader.Location ', ' char(roiHeader.Date)];['ROI sizes: ' num2str(roiHeader.Area.mean,2) '+/-' num2str(roiHeader.Area.std,2) ' ' roiHeader.Area.unit]},'Interpreter','none');

    hold on;
    % Fetch and plot Google Maps map constrained by the plotted GCPs
    plot_google_map('Axis', p.Results.Axis, ...
                    'Width', p.Results.Width, ...
                    'Height', p.Results.Height, ...
                    'Scale', p.Results.Scale, ...
                    'Resize', p.Results.Resize, ...
                    'MapType', p.Results.MapType, ...
                    'Alpha', p.Results.Alpha, ...
                    'ShowLabels', p.Results.ShowLabels, ...
                    'Style', p.Results.Style, ...
                    'Language', p.Results.Language, ...
                    'Refresh', p.Results.Refresh, ...
                    'AutoAxis', p.Results.AutoAxis, ...
                    'FigureResizeUpdate', p.Results.FigureResizeUpdate);
    % Add axis labels
    xlabel('Longitude, ^{\circ}','Interpreter','tex');
    ylabel('Latitude, ^{\circ}','Interpreter','tex');


end

