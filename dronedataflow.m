function dronedataflow

    %% Setup
    % Add drone dataflow functions to MATLAB path
    addpath(genpath('common'))
    
    % Create struct with GUI elements (tabs, descriptions and buttons)
    GUIstruct.name = 'Process single flight';
    GUIstruct.description = 'Process the images or maps from a single flight.';
    buttons.name = 'Detect GCPs';
    buttons.func = 'main_detectGCPs.m';
    buttons.description = 'Detect, review and export GCPs in images located in folder.';
    buttons(2).name = 'Extract ROIs';
    buttons(2).func = 'main_extractROIs.m';
    buttons(2).description = 'Extract ROIs from georeferenced maps.';
    GUIstruct.buttons = buttons;

    GUIstruct(2).name = 'Process multiple flights';
    GUIstruct(2).description = 'Process the images or maps from multiple flights.';
    clear buttons;
    buttons.name = 'Detect GCPs';
    buttons.func = 'batch_detectGPCs.m';
    buttons.description = 'Detect GCPs in images for several folders.';
    buttons(2).name = 'Review GCPs';
    buttons(2).func = 'batch_reviewROIs.m';
    buttons(2).description = 'Review detected GCPs for multiple folders.';
    buttons(3).name = 'Extract ROIs';
    buttons(3).func = 'batch_extractROIs.m';
    buttons(3).description = 'Extract ROIs from maps from multiple flights.';
    GUIstruct(2).buttons = buttons;
     
    GUIstruct(3).name = 'Utilities';
    GUIstruct(3).description = 'Utility functions';
    clear buttons;
    buttons.name = 'Crop map to polygon';
    buttons.func = fullfile('Utilities','main_cropMap.m');
    buttons.description = 'Specify interactively the corners of a polygon and crop the map to the polygon.';
    buttons(2).name = 'Show ROIs on map';
    buttons(2).func = fullfile('Utilities','main_showROIsOnMap.m');
    buttons(2).description = 'Load and plot ROIs on a user specified map.';
    GUIstruct(3).buttons = buttons;
    
    GUIstruct(4).name = 'Advanced';
    GUIstruct(4).description = 'Setup utilities';
    clear buttons;
    buttons.name = 'Create new camera model';
    buttons.func = fullfile('common','cameras','main_saveCameraModel.m');
    buttons.description = 'Specify parameters for a new camera model. Both perspective and fisheye models are supported.';
    GUIstruct(4).buttons = buttons;

    %%  Construct the components
    % Initial struct for handles
    handles = struct;
    handles.fig = figure('Visible','off','Position',[1 1 450 300],'Resize','off');
    % Remove built-in menu bar
    set(gcf,'MenuBar','none')
    % Remove figure number from title and set title of figure
    set(gcf, 'NumberTitle', 'off', 'Name', 'Drone Dataflow');
    
    % Create tabs
    handles.tgroup = uitabgroup('Parent', handles.fig,'TabLocation', 'left');
    for t = 1:length(GUIstruct)
        tabStruct = GUIstruct(t);
        handles.tab(t) = uitab('Parent', handles.tgroup, 'Title', tabStruct.name,'Units','Pixels');
        buttons = tabStruct.buttons;
        tabHandles = struct;
        for b = 1:length(buttons)
            action = buttons(b);
            % Create panel
            inner_position = get(handles.tab(t),'InnerPosition');
            handles.pan(b) = uipanel('Parent', handles.tab(t), ...
                                     'Title', action.name, ...
                                     'FontWeight','bold', ...
                                     'Units', 'Pixels', ...
                                     'Position', [10 inner_position(4)-(b*90) 300 80]); % inner_position(3)-(10+(b-1)*90)
            % Create description text
            tabHandles.text(b) = uicontrol('Parent', handles.pan(b), ...
                                           'Style', 'Text', ...
                                           'String', action.description, ...
                                           'HorizontalAlignment', 'Left', ...
                                           'Position', [5 5 200 60]);
            % Create "Run script" button
            tabHandles.btnRun(b) = uicontrol('Parent', handles.pan(b), ...
                                             'Style', 'PushButton', ...
                                             'String', 'Run script', ...
                                             'HorizontalAlignment', 'Center', ...
                                             'Position', [215 5 80 20], ...
                                             'Callback', {@callback_run, action});
            % Create "View code" button
            tabHandles.btnView(b) = uicontrol('Parent', handles.pan(b), ...
                                              'Style', 'PushButton', ...
                                              'String', 'View code', ...
                                              'HorizontalAlignment', 'Center', ...
                                              'Position', [215 30 80 20], ...
                                              'Callback', {@callback_view, action});
        end
    end
    
    
    %%  Initialization tasks
    
    % Set figure position to center of screen
    screen_size = get( groot, 'Screensize' );
    figure_position = get(handles.fig,'Position');
    figure_offset_left = (screen_size(3)-figure_position(3))/2;
    figure_offset_bottom = (screen_size(4)-figure_position(4))/2;
    set(handles.fig, 'Position',[figure_offset_left figure_offset_bottom figure_position(3:4)])
    
    % Show figure/GUI
    set(handles.fig,'Visible','on');
    
    %%  Set callbacks
    
    
    
end

function callback_run(hObject, callbackdata, button)
    disp('---------------------------')
    disp(['Action     : Run script'])
    disp(['Name       : ' button.name])
    disp(['Script     : ' button.func])
    disp(['Description: ' button.description])
    disp('---------------------------')
    run(button.func)
end

function callback_view(hObject, callbackdata, button)
    disp('---------------------------')
    disp(['Action     : View code'])
    disp(['Name       : ' button.name])
    disp(['Script     : ' button.func])
    disp(['Description: ' button.description])
    disp('---------------------------')
    open(button.func)
end