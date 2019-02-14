function [ h ] = plotGCPs( N, E, ID, GCPoptions)
%PLOTGCPS Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 4)
        GCPoptions = defaultGCPoptions();
    end;

    Ecm = mean(E);
    Ncm = mean(N);

    ax_tmp = gca;
       
    for i = 1:length(E)
        d = [E(i)-Ecm;
             N(i)-Ncm];
        d = d./norm(d);
        if (d(1) < 0)
            Eadd = 0.001*d(1);
            horAlign = 'right';
        else
            Eadd = 0.001*d(1);
            horAlign = 'left';
        end;
        if (d(2) < 0)
            Nadd = 0.0002*d(2);
            verAlign = 'top';
        else
            Nadd = 0.0002*d(2);
            verAlign = 'bottom';
        end;
        plot(E(i) + [0 Eadd]', N(i) + [0 Nadd]','-','Color',[1 0 0]);
        hold on;
        text(E(i) + Eadd, N(i) +Nadd, ID{i}, ...
            'BackgroundColor',[1 1 1], ...
            'FontUnits','pixels', ...
            'FontSize',12, ...
            'FontName','FixedWidth', ...
            'HorizontalAlignment',horAlign, ...
            'VerticalAlignment',verAlign);
    end;
    
    hold on;
    plot(E, N, 'x','LineWidth',1,'MarkerSize',7,'Color',[1 0 0]);
    hold on;
    h_tmp = plot(E, N, 'o','LineWidth',1,'MarkerSize',7,'Color',[1 0 0]);

    if (nargout > 0)
        h = h_tmp;
    end;

end

function GCPoptions = defaultGCPoptions()
    GCPoptions = [];
end