function plotOverviewMap( longitude, latitude, varargin)
%PLOTOVERVIEW Summary of this function goes here
%   Detailed explanation goes here

% Parse optional name-value pairs
p = inputParser; % Initiate parser
addParameter(p,'Axis',gca); % Add default values to (optional) parameters
addParameter(p,'Width',640);
addParameter(p,'Height',480);
addParameter(p,'Scale',2);
addParameter(p,'Resize',1);
addParameter(p,'MapType','hybrid');
addParameter(p,'Alpha',1);
addParameter(p,'ShowLabels',1);
addParameter(p,'Style','');
addParameter(p,'Language','');
addParameter(p,'Refresh',1);
addParameter(p,'AutoAxis',1);
addParameter(p,'FigureResizeUpdate',1);
parse(p, varargin{:}); % Parse inputs

% [latitude, longtitude] = utm2ell(utmNorth, utmEast, zone);
% lat = latitude/pi*180;
% long = longtitude/pi*180;

XLim = round((longitude*10/5))*5/10 + [-4.5 4.5];
YLim = round((latitude*10/5))*5/10 + [-4.5 4.5];

plot(longitude,latitude,'rx')
hold on;
plot(longitude,latitude,'ro')
title('Overview')
% axis off;
axis equal;
set(gca,'XLim',XLim)
set(gca,'YLim',YLim)
set(gca,'DataAspectRatio',[2 1 1]);
% Fetch and plot Google Maps map constrained by the plotted GCPs
plot_google_map('Axis', gca, ...
                'Width', p.Results.Width, ...
                'Height', p.Results.Height, ...
                'Scale', p.Results.Scale, ...
                'Resize', p.Results.Resize, ...
                'MapType', 'hybrid', ...
                'Alpha', p.Results.Alpha, ...
                'ShowLabels', p.Results.ShowLabels, ...
                'Style', p.Results.Style, ...
                'Language', p.Results.Language, ...
                'Refresh', p.Results.Refresh, ...
                'AutoAxis', p.Results.AutoAxis, ...
                'FigureResizeUpdate', p.Results.FigureResizeUpdate);
% Add axis labels
xlabel('Longtitude, ^{\circ}','Interpreter','tex');
ylabel('Latitude, ^{\circ}','Interpreter','tex');
set(gca,'XLim',XLim)
set(gca,'YLim',YLim)

end

