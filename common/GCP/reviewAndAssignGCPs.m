function [markersReviewed,GCPsOut] = reviewAndAssignGCPs(markers, GCPs, varargin)
    %REVIEWANDASSIGNGCPS Summary of this function goes here
    %   Detailed explanation goes here
    markersReviewed = markers;
    GCPsOut = GCPs;
    
    defaultMap = [];
    defaultMapRaster = [];
    defaultFigureName = '';
    defaultAssignFunc = 'assignGCPs';
    defaultGCPids = unique([markersReviewed.ID]); % unique(cellfun(@(x) {num2str(x)},num2cell([markers.ID])))
    
    p = inputParser;
    addParameter(p,'map', defaultMap);
    addParameter(p,'mapRaster', defaultMapRaster);
    addParameter(p,'name', defaultFigureName);
    parse(p,varargin{:});
    
    map = p.Results.map;
    mapRaster = p.Results.mapRaster;
    if (any(size(map) > 1000))
        scale = 1./max(size(map)/1000);
        map = imresize(map,scale);
        mapRaster.RasterSize = size(map);
    end
    
    GCPreviewPlotSize = [150, 150]; %100;
    GCPreviewPlotSpacing = 30; %15;
    GCPreviewPlotHeaderSpace = 30; %15;
    
    
    %%  Initialization tasks
    
    % Setup figure
    handles.figure = figure('Visible','off');
    screenPosition = get(0, 'Screensize');
    set(handles.figure,'units','pixels','outerposition',[-4 35 screenPosition(3)+10 screenPosition(4)-35]);
    set(handles.figure,'resize','off');
    set(handles.figure,'MenuBar','none');
    set(handles.figure,'NumberTitle','off','Name',['Review and assign GCPs:   ' p.Results.name]);
    
    setappdata(handles.figure,'markers',markers);
    setappdata(handles.figure,'markersReviewed',markers);
    markersID = unique([markers.ID]);
    setappdata(handles.figure,'markerIDs',markersID);
    setappdata(handles.figure,'GCPs',GCPs);
    setappdata(handles.figure,'GCPsReviewed',GCPs);
    GCPcmap = distinguishable_colors(8, [1 1 1; 0 0 0; 0 0 1]);
    setappdata(handles.figure,'GCPcmap',GCPcmap);
    
    setappdata(handles.figure,'GCPreviewPlotSize',GCPreviewPlotSize);
    setappdata(handles.figure,'GCPreviewPlotSpacing',GCPreviewPlotSpacing);
    setappdata(handles.figure,'GCPreviewPlotHeaderSpace',GCPreviewPlotHeaderSpace);
    
    setappdata(handles.figure,'map',map);
    setappdata(handles.figure,'mapRaster',mapRaster);
    
    %%  Construct the components


    % Setup tabs
    handles.tabGroup = uitabgroup('Parent', handles.figure,'TabLocation', 'top');
    handles.tabReview = uitab('Parent', handles.tabGroup, 'Title', '   Review   ','Units','Pixels');
    handles.tabAssign = uitab('Parent', handles.tabGroup, 'Title', '   Assign   ','Units','Pixels');

    % Review tab
    handles.review.GCPlistboxTitle = uicontrol('Parent',handles.tabReview,'Style','text','String','Detected GCPs in images:','Units','Pixels','HorizontalAlignment','Left','FontSize',12);
    handles.review.GCPlistbox = uicontrol('Parent',handles.tabReview,'Style','listbox','Units','Pixels','FontSize',10,'FontUnits','Pixels','FontWeight','bold');
    handles.review.GCPpreview = axes('Parent',handles.tabReview,'Units','Pixels','Box','off','Visible','off');
    handles.review.GCPoverview = axes('Parent',handles.tabReview,'Units','Pixels','Box','off','Visible','off');
    handles.review.GCPreview = axes('Parent',handles.tabReview,'Units','Pixels','Box','on','Visible','on');
    handles.review.GCPreviewSlider = uicontrol('Parent',handles.tabReview,'Style', 'slider', 'Min', 0, 'Max', 1, 'Value', 1);

    % Assign tab
    handles.assign.assignTableColumnsHeader = uicontrol('Parent',handles.tabAssign,'Style','text','String','GCPs in world','Units','Pixels','HorizontalAlignment','Left','FontSize',12);
%     handles.assign.assignTableRowsHeader = uicontrol('Parent',handles.tabAssign,'Style','text','String','GCPs in images','Units','Pixels','HorizontalAlignment','Left');
    handles.assign.assignTableRowsHeaderAxes = axes('Parent',handles.tabAssign,'Units','Pixels','Box','on','Visible','on');
    handles.assign.assignTable = uitable('Parent',handles.tabAssign,'Data',zeros(length(markersID),length(GCPs)));
    handles.assign.assignResetButton = uicontrol('Parent',handles.tabAssign,'Style','pushbutton','Units','Pixels','String','Reset','FontUnits','Pixels','FontSize',15);
    
    handles.assign.assignOverview = axes('Parent',handles.tabAssign,'Units','Pixels','Box','on','Visible','on');

    % Update GUI positions
    setGUIpositions(handles);
    
    %%  Initialization tasks
    
    resetAssignPrior(handles);
    updateAssignment(handles);
    
    setReviewGCPlistbox(handles);
    plotReviewGCPpreview(handles);
    plotReviewGCPoveriew(handles);
    plotReviewGCPreview(handles);
    
    % Show figure after everything has been setup
    set(handles.figure,'Visible','on');
    
    %%  Set callbacks
    
    % Add callbacks
    set(handles.figure, 'DeleteFcn', {@callback_figureClose, handles});
    set(handles.figure, 'SizeChangedFcn', {@callback_figureResize, handles})
    set(handles.review.GCPlistbox, 'Callback', {@callback_reviewGCPlistbox_select, handles});
    set(handles.review.GCPreviewSlider ,'Callback', {@callback_reviewSlider, handles});
    %set(handles.review.GCPreview,'HitTest','on','ButtonDownFcn',{@callback_reviewAxes, handles});
    
    set(handles.tabGroup,'SelectionChangedFcn', {@callback_tabSelectionChanged, handles});
    set(handles.assign.assignTable,'CellEditCallback', {@callback_editAssignTable, handles});
    set(handles.assign.assignResetButton,'Callback', {@callback_assignResetButton, handles});
    
    %% Handle outputs
       
    % Wait for UI to close before proceeding
    waitfor(handles.figure);
    
    global markersReviewed_global;
    global GCPsReviewed_global;
    markersReviewed = markersReviewed_global;
    GCPsOut = GCPsReviewed_global;
    clear global markersReviewed_global;
    clear global GCPsReviewed_global;
    
end

%% Callbacks

function callback_figureClose(~, ~, handles)
    global markersReviewed_global;
    global GCPsReviewed_global;
    markersReviewed_global = getappdata(handles.figure,'markersReviewed');
    GCPsReviewed_global = getappdata(handles.figure,'GCPsReviewed');
end

function callback_tabSelectionChanged(hobject, callbackdata, handles)
    if (hobject.SelectedTab == handles.tabReview) % Review tab selected
        setGUIpositionsReview(handles);
    elseif (hobject.SelectedTab == handles.tabAssign) % Assign tab selected
        setGUIpositionsAssign(handles);
        
        if (~isappdata(handles.figure,'assignPriorUser'))
            resetAssignPrior(handles);
        end
        updateAssignment(handles);
        
        updateAssignTable(handles);
        plotAssignOveriew(handles);
    end
end

function callback_editAssignTable(hObject, callbackdata, handles)
    updateUserPrior(handles, callbackdata.Indices);
    
    updateAssignment(handles);

    updateAssignTable(handles);
    plotAssignOveriew(handles);
end

function callback_assignResetButton(hobject, callbackdata, handles)
    resetAssignPrior(handles);
    
    updateAssignment(handles);
        
    updateAssignTable(handles);
    plotAssignOveriew(handles);
end

function updateUserPrior(handles, indices)
    if (isappdata(handles.figure,'assignPriorUser'))
        assignPriorUser = getappdata(handles.figure, 'assignPriorUser');
    else
        markers = getappdata(handles.figure, 'markersReviewed');
        GCPs = getappdata(handles.figure, 'GCPsReviewed');
        assignPriorUser = zeros(length(unique([markers([markers.isMarker]).ID])),length(GCPs),'logical');
    end
    
    assignTable = get(handles.assign.assignTable,'Data');
    
    if (assignTable(indices(1),indices(2)))
        assignPriorUser(:,indices(2)) = 0;
        assignPriorUser(indices(1),indices(2)) = 1;
    else
        assignPriorUser(:,indices(2)) = 1./size(assignPriorUser,1);
        assignPriorUser(indices(1),indices(2)) = 0;
    end
    
    setappdata(handles.figure, 'assignPriorUser',assignPriorUser);
end

function callback_reviewGCPlistbox_select(hObject, callbackdata, handles)
    plotReviewGCPpreview(handles);
    plotReviewGCPoveriew(handles);
    plotReviewGCPreview(handles);
end

function callback_figureResize(hObject, callbackdata, handles)
    setGUIpositions(handles);
    plotReviewGCPreview(handles);
end

function callback_reviewSlider(hObject, callbackdata, handles)
    sMin = get(handles.review.GCPreviewSlider,'Min');
    sMax = get(handles.review.GCPreviewSlider,'Max');
    sStep = get(handles.review.GCPreviewSlider,'SliderStep');
    sValue = get(handles.review.GCPreviewSlider,'Value');
    GCPreviewPlotSize = getappdata(handles.figure,'GCPreviewPlotSize');
    GCPreviewPlotSpacing = getappdata(handles.figure,'GCPreviewPlotSpacing');
    GCPreviewPlotHeaderSpace = getappdata(handles.figure,'GCPreviewPlotHeaderSpace');
    
%     disp([sMin sMax sStep sValue]);
    
    reviewAreaPosition = get(handles.review.GCPreview,'InnerPosition');
    GCPreviewNrowsView = getappdata(handles.figure,'GCPreviewNrowsView');
    GCPreviewNrows = getappdata(handles.figure,'GCPreviewNrows');
    
    set(handles.review.GCPreview,'XLim',[0 reviewAreaPosition(3)], ...
                                 'YLim',(((GCPreviewNrows - GCPreviewNrowsView)) - sValue)*(GCPreviewPlotSize(1) + GCPreviewPlotHeaderSpace + GCPreviewPlotSpacing) + [0 reviewAreaPosition(4)]);
    
end

function callback_reviewAxes(hObject, callbackdata, handles)
%     disp('Axes review clicked!');
    markerClicked = hObject.UserData;
%     disp(markerClicked);
    markers = getappdata(handles.figure,'markersReviewed');
    markerIDs = getappdata(handles.figure,'markerIDs');
    selectedGCPidx = get(handles.review.GCPlistbox,'Value');    
    
    marker = markers(markerClicked(1));
    marker.isMarker = not(marker.isMarker);
    markers(markerClicked(1)) = marker;
    
    setappdata(handles.figure, 'markersReviewed',markers);
    
    theseMarkers = getMarkersWidthSelectedID(markers, markerIDs, selectedGCPidx);
    updateReviewMarkerHighlights(handles, theseMarkers);
    plotReviewGCPoveriew(handles);
    setReviewGCPlistbox(handles);
end

%% Utility functions

function setGUIpositions(handles)
    % Set GUI positions in Review tab
    setGUIpositionsReview(handles);
    % Set GUI positions in Assign tab
    setGUIpositionsAssign(handles);
end

function setGUIpositionsReview(handles)
    % Set positions for Review tab
    set(handles.review.GCPlistboxTitle,'Units','Pixels','Position',ltwh2lbwh([10 15 300 20], get(handles.tabReview,'InnerPosition')));
    set(handles.review.GCPlistbox,'Units','Pixels','Position',ltwh2lbwh([10 35 300 130], get(handles.tabReview,'InnerPosition')));
    set(handles.review.GCPpreview,'Units','Pixels','Position',ltwh2lbwh([50 185 200 200], get(handles.tabReview,'InnerPosition')));
    set(handles.review.GCPoverview,'Units','Pixels','Position',ltwh2lbwh([10 405 300 -100], get(handles.tabReview,'InnerPosition')));
    set(handles.review.GCPreview,'Units','Pixels','Position',ltwh2lbwh([340 15 -30 -10],get(handles.tabReview,'InnerPosition')));
    set(handles.review.GCPreviewSlider,'Units','Pixels','Position',ltwh2lbwh([-25 15 15 -10],get(handles.tabReview,'InnerPosition')));
end

function setGUIpositionsAssign(handles)
    % Set positions for Assign tab
    set(handles.assign.assignTableColumnsHeader, 'Units','Pixels','Position',ltwh2lbwh([65 15 280 20], get(handles.tabAssign,'InnerPosition')));
%     set(handles.assign.assignTableRowsHeader, 'Units','Pixels','Position',ltwh2lbwh([10 55 20 300], get(handles.tabAssign,'InnerPosition')));
    set(handles.assign.assignTableRowsHeaderAxes, 'Units','Pixels','Position',ltwh2lbwh([10 55 20 280], get(handles.tabAssign,'InnerPosition')));
    set(handles.assign.assignTableRowsHeaderAxes,'XLim',[-1 1],'YLim',[-1 1], 'Box', 'off','Visible','off');
    h = gca;
    axes(handles.assign.assignTableRowsHeaderAxes);
    text(1,1,'GCPs in images','Rotation',90,'HorizontalAlign','right','FontName','MS Sans Serif','FontSize',12,'FontUnits','points');
    axes(h);
    set(handles.assign.assignTable, 'Units', 'Pixels', 'Position', ltwh2lbwh([45 35 300 300], get(handles.tabAssign,'InnerPosition')));
    set(handles.assign.assignResetButton, 'Units','Pixels','Position',ltwh2lbwh([45 355 100 30], get(handles.tabAssign,'InnerPosition')));
    set(handles.assign.assignOverview, 'Units','Pixels','Position',ltwh2lbwh([340 15 -30 -30],get(handles.tabAssign,'InnerPosition')));
end

function lbwhPosition = ltwh2lbwh(ltwhPosition, lbwhParentPosition)
    % LTWH2LBWH Converts from left-top-width-height to left-bottom-width-height
    if (ltwhPosition(1) < 0)
        left = lbwhParentPosition(3) + ltwhPosition(1);
    else
        left = ltwhPosition(1);
    end
    
    if (ltwhPosition(3) < 0)
        width = lbwhParentPosition(3) - left + ltwhPosition(3);
    else
        width = ltwhPosition(3);
    end
    
    if (ltwhPosition(4) < 0)
        height = lbwhParentPosition(4) - ltwhPosition(2) + ltwhPosition(4);
    else
        height = ltwhPosition(4);
    end
    
    bottom = lbwhParentPosition(4) - (ltwhPosition(2)+height);
    lbwhPosition = [left bottom width height];
    
end

function setReviewGCPlistbox(handles)
    markers = getappdata(handles.figure,'markersReviewed');
    markerIDs = getappdata(handles.figure,'markerIDs');
    GCPcmap = getappdata(handles.figure,'GCPcmap');
    
    listboxStrings = cell(1,length(markerIDs));
    for i = 1:length(markerIDs)
        thisMarkers = markers([markers.ID] == markerIDs(i));
        hex = rgb2hex(GCPcmap(i,:));
        thisString = ['<HTML><FONT color="' hex '">Id: ' num2str(markerIDs(i)) ' (' num2str(sum([thisMarkers.isMarker] == true)) '/' num2str(length(thisMarkers)) ')</FONT></HTML>'];
        listboxStrings{i} = thisString;
    end
    set(handles.review.GCPlistbox,'String',listboxStrings);
end

function plotReviewGCPpreview(handles)
    markerIDs = getappdata(handles.figure,'markerIDs');
    selectedGCPidx = get(handles.review.GCPlistbox,'Value');
    axes(handles.review.GCPpreview);
%     I = imread(['C:\gitlab\drone-dataflow\Images\GCP' num2str(markerIDs(selectedGCPidx)) '.png']);
    I = imread(fullfile(droneDataflowPath( ), 'common','GCP','Images',['GCP' num2str(markerIDs(selectedGCPidx)) '.png']));
    imshow(I);
end

function plotReviewGCPoveriew(handles)
    GCPs = getappdata(handles.figure,'GCPs');
    markers = getappdata(handles.figure,'markersReviewed');
    markerIDs = getappdata(handles.figure,'markerIDs');
    GCPcmap = getappdata(handles.figure,'GCPcmap');
    map = getappdata(handles.figure,'map');
    mapRaster = getappdata(handles.figure,'mapRaster');
    
    selectedGCPidx = get(handles.review.GCPlistbox,'Value');
    axes(handles.review.GCPoverview);
    cla;
    if (~isempty(map) && ~isempty(mapRaster))
        mapshow(map, mapRaster)
        hold on;
    end
    plot([GCPs.UTMEast],[GCPs.UTMNorth],'wx','MarkerSize',11,'LineWidth',2);
    hold on;
    plot([GCPs.UTMEast],[GCPs.UTMNorth],'kx','MarkerSize',10,'LineWidth',1);
    for m = 1:length(markerIDs)
        markersIdx = [markers.ID] == markerIDs(m);
        if (m == selectedGCPidx)
            % Skip for now
        else
            plot([markers(and(markersIdx, [markers.isMarker])).UTMEast],[markers(and(markersIdx, [markers.isMarker])).UTMNorth],'o','markerSize',2,'color',GCPcmap(m,:),'MarkerFaceColor',GCPcmap(m,:));
        end
    end
    % Draw selected GCPs
    m = selectedGCPidx;
    markersIdx = [markers.ID] == markerIDs(m);
    plot([markers(and(markersIdx, [markers.isMarker])).UTMEast],[markers(and(markersIdx, [markers.isMarker])).UTMNorth],'o','markerSize',5,'color',GCPcmap(m,:),'MarkerFaceColor',GCPcmap(m,:));
    plot([markers(and(markersIdx,~[markers.isMarker])).UTMEast],[markers(and(markersIdx,~[markers.isMarker])).UTMNorth],'o','markerSize',5,'color',GCPcmap(m,:),'MarkerFaceColor','none');
    
    set(handles.review.GCPoverview,'Box','on','Visible','on');
    set(handles.review.GCPoverview,'DataAspectRatio',[1 1 1],'PlotBoxAspectRatio',[1 1 1]);
    set(handles.review.GCPoverview,'xtick',[],'xticklabel',[]);
    set(handles.review.GCPoverview,'ytick',[],'yticklabel',[]);
    xlabel('East $\rightarrow$','Interpreter','latex');
    ylabel('North $\rightarrow$','Interpreter','latex');
end

function plotReviewGCPreview(handles)
    markers = getappdata(handles.figure,'markersReviewed');
    markerIDs = getappdata(handles.figure,'markerIDs');
    selectedGCPidx = get(handles.review.GCPlistbox,'Value');
    reviewAreaPosition = get(handles.review.GCPreview,'InnerPosition');
    GCPreviewPlotSize = getappdata(handles.figure,'GCPreviewPlotSize');
    GCPreviewPlotSpacing = getappdata(handles.figure,'GCPreviewPlotSpacing');
    GCPreviewPlotHeaderSpace = getappdata(handles.figure,'GCPreviewPlotHeaderSpace');
    
%     markerIdx = find([markers.ID] == markerIDs(selectedGCPidx));

    [theseMarkers, markerIdx] = getMarkersWidthSelectedID(markers, markerIDs, selectedGCPidx);

    Nmarkers = length(markerIdx);
    Ncolumns = floor((reviewAreaPosition(3) + GCPreviewPlotSpacing)/(GCPreviewPlotSize(2) + GCPreviewPlotSpacing));
    NrowsView = floor((reviewAreaPosition(4) + GCPreviewPlotHeaderSpace + GCPreviewPlotSpacing)/(GCPreviewPlotSize(1) + GCPreviewPlotHeaderSpace + GCPreviewPlotSpacing));
    Nrows = ceil(Nmarkers/Ncolumns);
    
    axes(handles.review.GCPreview);
    cla;
    
    xOffsets = zeros(1,Nmarkers);
    yOffsets = zeros(1,Nmarkers);
    for i = 1:Nmarkers
        r = floor((i-1)/Ncolumns);
        c = i - (r*Ncolumns + 1);
        xOffset = c*(GCPreviewPlotSize(2) + GCPreviewPlotSpacing);
        yOffset = r*(GCPreviewPlotSize(1) + GCPreviewPlotHeaderSpace + GCPreviewPlotSpacing);
        xOffsets(i) = xOffset;
        yOffsets(i) = yOffset;
        hImage = image(xOffset + [0 GCPreviewPlotSize(2)], yOffset + GCPreviewPlotHeaderSpace + [0 GCPreviewPlotSize(1)], repmat(theseMarkers(i).thumbnail.ImageRotated,[1 1 3]));
        set(hImage,'HitTest','on','ButtonDownFcn',{@callback_reviewAxes, handles});
        set(hImage,'UserData',[markerIdx(i) i]);
        hold on;
        
        if (~theseMarkers(i).isMarker)
            plot(xOffset + [0 GCPreviewPlotSize(2)],yOffset + GCPreviewPlotHeaderSpace + [0 GCPreviewPlotSize(1)],'-r','LineWidth',3,'UserData',i,'Hittest','off','PickableParts','none');
        end
%         plot(xOffset + [0 GCPreviewPlotSize(2) GCPreviewPlotSize(2) 0 0], yOffset + [0 0 (GCPreviewPlotSize(1)+GCPreviewPlotHeaderSpace) (GCPreviewPlotSize(1)+GCPreviewPlotHeaderSpace) 0],'-');
        
        text(xOffset, yOffset+15,[num2str(i) ' (' num2str(abs(theseMarkers(i).response),'%.1f') ')'],'VerticalAlignment','Bottom','Interpreter','none','fontsize',10);
        text(xOffset, yOffset+25,theseMarkers(i).imageName,'VerticalAlignment','Bottom','Interpreter','none','fontsize',6);
%         text(xOffset + GCPreviewPlotSize(2)/2, yOffset + GCPreviewPlotSize(1)/2,num2str([i r c]),'HorizontalAlignment','center');
    end
    
    axis ij;
    set(handles.review.GCPreview,'XLim',[0 reviewAreaPosition(3)], ...
                                 'YLim',[0 reviewAreaPosition(4)]);

    set(handles.review.GCPreview,'Box','off', ...
                                 'Visible','off', ...
                                 'xtick',[], ...
                                 'xticklabel',[], ...
                                 'ytick',[], ...
                                 'yticklabel',[]);
                             
    set(handles.review.GCPreviewSlider,'Min',0,'Max',Nrows-NrowsView,'Value',Nrows-NrowsView)
    if (Nrows-NrowsView-1 > 0)
        set(handles.review.GCPreviewSlider,'SliderStep', 1./(Nrows-NrowsView-1)*[0.5 1]);
    end
    setappdata(handles.figure,'GCPreviewNrowsView',NrowsView);
    setappdata(handles.figure,'GCPreviewNrows',Nrows);
    setappdata(handles.figure,'GCPreviewXoffsets',xOffsets);
    setappdata(handles.figure,'GCPreviewYoffsets',yOffsets);
    
end

function [theseMarkers, markerIdx] = getMarkersWidthSelectedID(markers, markerIDs, selectedGCPidx)
    markerIdx = find([markers.ID] == markerIDs(selectedGCPidx));
    theseMarkers = markers(markerIdx);
end

function updateReviewMarkerHighlights(handles, theseMarkers)

    % Get all lines in review axes
    ch = get(handles.review.GCPreview,'Children');
    isLine = zeros(size(ch),'logical');
    for i = 1:length(isLine)
        if (isa(ch(i),'matlab.graphics.chart.primitive.Line'))
            isLine(i) = 1;
        end
    end
    hLines = ch(isLine);
    
    % Get index of all lines
    lineIdx = [];
    if (~isempty(hLines))
        lineIdx = [hLines.UserData];
    end
    
    % Get index of all non-markers
    markersIdx = find(~[theseMarkers.isMarker]);
    
    [~, lineIdxRemove, markerAddIdx] = setxor(lineIdx,markersIdx);
    lineIdx(lineIdxRemove);
    markersIdx(markerAddIdx);
    
    % Remove
%     lineIdx(lineIdxRemove)
    for l = 1:length(lineIdxRemove)
        delete(hLines(lineIdxRemove(l)));
    end
    
    % Add new
    if (~isempty(markerAddIdx))
        xOffsets = getappdata(handles.figure,'GCPreviewXoffsets');
        yOffsets = getappdata(handles.figure,'GCPreviewYoffsets');
%         reviewAreaPosition = get(handles.review.GCPreview,'InnerPosition');
        GCPreviewPlotSize = getappdata(handles.figure,'GCPreviewPlotSize');
%         GCPreviewPlotSpacing = getappdata(handles.figure,'GCPreviewPlotSpacing');
        GCPreviewPlotHeaderSpace = getappdata(handles.figure,'GCPreviewPlotHeaderSpace');
        for m = 1:length(markerAddIdx)
            markerIdx = markersIdx(markerAddIdx(m));
            xOffset = xOffsets(markerIdx);
            yOffset = yOffsets(markerIdx);
            plot(xOffset + [0 GCPreviewPlotSize(2)],yOffset + GCPreviewPlotHeaderSpace + [0 GCPreviewPlotSize(1)],'-r','LineWidth',3,'UserData',markerIdx,'Hittest','off','PickableParts','none');
        end
    end

end

function resetAssignPrior(handles)
    markers = getappdata(handles.figure, 'markersReviewed');
    GCPs = getappdata(handles.figure, 'GCPsReviewed');
    assignPriorUser = ones(length(unique([markers.ID])),length(GCPs))./length(GCPs);
    setappdata(handles.figure, 'assignPriorUser',assignPriorUser);
end

function updateAssignment(handles)
    markers = getappdata(handles.figure, 'markersReviewed');
    GCPs = getappdata(handles.figure, 'GCPsReviewed');
    assignPriorUser = getappdata(handles.figure, 'assignPriorUser');
    [markers, GCPs] = assignGCPs(markers, GCPs, assignPriorUser);
    setappdata(handles.figure, 'markersReviewed', markers);
    setappdata(handles.figure,'GCPsReviewed', GCPs);
end

function updateAssignTable(handles)
    GCPs = getappdata(handles.figure, 'GCPsReviewed');
    markers = getappdata(handles.figure, 'markersReviewed');
    GCPcmap = getappdata(handles.figure,'GCPcmap');
    IDs = unique([markers.ID]);
    markerIDs = getappdata(handles.figure,'markerIDs');
    
    GCPids = {GCPs.name};
    assignMatrix = zeros(length(IDs),length(GCPids),'logical');
    for m = 1:length(markerIDs)
        markersIdx = [markers.ID] == markerIDs(m);
        markerPlotIdx = and(markersIdx, [markers.isMarker]);
        
        GCPidx = unique([markers(markerPlotIdx).GCPidx]);
        for g = 1:length(GCPidx)
            assignMatrix(m,GCPidx(g)) = true;
        end
        
    end
    
    assignPriorUser = getappdata(handles.figure, 'assignPriorUser');
    for c = 1:size(assignMatrix,2)
        if (sum(assignMatrix(:,c)) == 0)
            assignMatrix(find(assignPriorUser(:,c) == 1),c) = 1;
        end
    end
    
%     disp(assignMatrix);

%     set(handles.assign.assignTable,'RowName',cellfun(@num2str, num2cell(IDs),'UniformOutput',false));
    set(handles.assign.assignTable,'RowName',cell(size(IDs))); %cellfun(@num2str, num2cell(IDs),'UniformOutput',false));
    set(handles.assign.assignTable, 'ColumnName',GCPids, ...
                                    'ColumnWidth',num2cell(cellfun(@length,GCPids).*20), ...
                                    'ColumnEditable',true, ...
                                    'ColumnFormat',repmat({'logical'},1,length(GCPids)));
    set(handles.assign.assignTable,'Data', assignMatrix);
    set(handles.assign.assignTable,'BackgroundColor',GCPcmap(1:length(IDs),:));
end

function plotAssignOveriew(handles)
    GCPs = getappdata(handles.figure,'GCPs');
    markers = getappdata(handles.figure,'markersReviewed');
    markerIDs = getappdata(handles.figure,'markerIDs');
    GCPcmap = getappdata(handles.figure,'GCPcmap');
    map = getappdata(handles.figure,'map');
    mapRaster = getappdata(handles.figure,'mapRaster');
    
    axes(handles.assign.assignOverview);
    cla;
    
    if (~isempty(map) && ~isempty(mapRaster))
        mapshow(map, mapRaster)
        hold on;
    end
    
    % Plot detected markers
    for m = 1:length(markerIDs)
        markersIdx = [markers.ID] == markerIDs(m);
        markerPlotIdx = and(markersIdx, [markers.isMarker]);
        if (~isempty([markers(markerPlotIdx).GCPidx]))
            plot([[markers(markerPlotIdx).UTMEast]; [GCPs([markers(markerPlotIdx).GCPidx]).UTMEast]],[[markers(markerPlotIdx).UTMNorth]; [GCPs([markers(markerPlotIdx).GCPidx]).UTMNorth]],'-','color', [1 1 1],'LineWidth',2);
            hold on;
            plot([[markers(markerPlotIdx).UTMEast]; [GCPs([markers(markerPlotIdx).GCPidx]).UTMEast]],[[markers(markerPlotIdx).UTMNorth]; [GCPs([markers(markerPlotIdx).GCPidx]).UTMNorth]],'-','color', GCPcmap(m,:),'LineWidth',1);
        end
        plot([markers(markerPlotIdx).UTMEast],[markers(markerPlotIdx).UTMNorth],'o','markerSize',7,'MarkerFaceColor',GCPcmap(m,:),'MarkerEdgeColor',[1 1 1]);
        hold on;

    end
    
    % Plot GCPs
    for g = 1:length(GCPs)
        text(GCPs(g).UTMEast,GCPs(g).UTMNorth,GCPs(g).name,'HorizontalAlignment','center','VerticalAlignment','middle','FontWeight','bold','FontSize',14,'Color',[1 1 1]);
        text(GCPs(g).UTMEast,GCPs(g).UTMNorth,GCPs(g).name,'HorizontalAlignment','center','VerticalAlignment','middle','FontWeight','normal','FontSize',12,'Color',[0 0 0]);
    end
    
    set(handles.assign.assignOverview,'Box','on','Visible','on');
    set(handles.assign.assignOverview,'DataAspectRatio',[1 1 1],'PlotBoxAspectRatio',[1 1 1]);
    set(handles.assign.assignOverview,'xtick',[],'xticklabel',[]);
    set(handles.assign.assignOverview,'ytick',[],'yticklabel',[]);
    xlabel('East $\rightarrow$','Interpreter','latex');
    ylabel('North $\rightarrow$','Interpreter','latex');
end

function hex = rgb2hex(rgb)
    % Convert rgb values to hex values for html
    hex = char(zeros(size(rgb,1),7));
    rgb = round(255*rgb);
    for i = 1:size(rgb,1)
        hex(i,:) = ['#' dec2hex(rgb(i,1),2), dec2hex(rgb(i,2),2), dec2hex(rgb(i,3),2)];
    end
end