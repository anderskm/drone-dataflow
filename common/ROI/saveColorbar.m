function saveColorbar( outputname, cmap, range, format )
%SAVECOLORBAR Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 4)
        format = '%.2e';
    end

    minMax = range;

    fig = figure('Position',[100 100 10 315],'Units','Pixels');
    set(fig, 'PaperPositionMode', 'auto'); % Make sure that the saved legend has the same size and the displayed legend
    colormap(cmap);
    h = colorbar('Ticks',linspace(0,1,7),'TickLabels',num2str(linspace(minMax(1), minMax(2),7)',format));
    axis off;
    h.Units = 'Pixels';
    h.Position = [10 10 30 300];
    h.TickDirection = 'out';
    h.AxisLocation = 'in';
    drawnow;
    
%     outputname = [name '_color_' colormaps{c} '_legend.png'];
    disp(['      Saving colorbar: ' outputname]);
    saveas(fig, outputname ,'png');
    close(fig);
    pause(0);

end

