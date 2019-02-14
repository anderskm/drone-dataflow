function showGCPsOnMap( latitude, longtitude, id,  GCPoptions, mapProvider ,varargin)
%SHOWGCPSONMAP Summary of this function goes here
%   Detailed explanation goes here
%
% USAGE:
%   showGCPsOnMap( latitude, longtitude, id,  GCPoptions )
%   showGCPsOnMap( latitude, longtitude, id,  GCPoptions, mapProvider , ... )
%   showGCPsOnMap( latitude, longtitude, id,  GCPoptions, 'Google')
%   showGCPsOnMap( latitude, longtitude, id,  GCPoptions, 'Google', name, value, ...)
%   showGCPsOnMap( latitude, longtitude, id,  GCPoptions, 'Geotiff' , map, mapTransformation )
%
% INPUTS:
%   latitude          - vector of latitude of the GCPs. Must be in degrees.
%   longtitude        - vector of longtitude of the GCPs. Must be in degrees.
%   id                - cell vector of strings with the IDs of the GCPs.
%   GCPoptions        - struct with plotting options for the GCPs.
%                       See plotGCPs for more information.
%   mapProvider       - Specifies which map provider to use. If 'Google', 
%                       uses Google Maps. If 'GeoTiff', use user specified
%                       map and mapTransformation. Default: 'Google'.
%   map               - image/map read from a geotiff. See geotiffread for 
%                       more information.
%   mapTransformation - map transformation read from a geotiff. See
%                       geotiffread for more information.
%   name,value        - See plot_google_map for more information.
%                       Note: Marker and APIKey parameters are not
%                       available through showGCPsOnMap.
%                       

    if (nargin < 5)
        mapProvider = 'Google';
    end;

    % Use Google Maps
    if (strcmpi(mapProvider,'Google') || isempty(mapProvider))
        
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
        
        % Plot GCPs
        plotGCPs(latitude,longtitude,id, GCPoptions);
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
        xlabel('Longtitude, ^{\circ}','Interpreter','tex');
        ylabel('Latitude, ^{\circ}','Interpreter','tex');
        
    % Use provided geotiff map
    elseif (strcmpi(mapProvider,'Geotiff'))
        % Convert coordinates to UTM
        [E, N, zone] = ll2utm(latitude, longtitude);
        % Fetch map and map transformation from inputs
        map = varargin{1};
        mapTransformation = varargin{2};
        
        % Show map
        mapshow(map(:,:,1), mapTransformation);
        hold on;
        % Plot GCPs
        plotGCPs(N,E,id);
        % Add axis labels
        xlabel('UTM east, m');
        ylabel('UTM north, m');
    end;

end
