function [ MW ] = poly2weightedmask( x, y, m, n )
%POLY2WEIGHTEDMASK Summary of this function goes here
%   Detailed explanation goes here
%
%
% Notes:
% - poly2weightedmask is several hundre times slower than poly2mask
% (determined emperically).
%
% See also: poly2mask

%% Find all pixels where the centre is inside the polygon

[X,Y] = meshgrid(1:n, 1:m);
MW = double(inpolygon(X,Y,x,y));

%% Find pixels intersected by the lines between the vertices

% Find edges
edges = struct([]);
xE = [x(:)' x(1)];
yE = [y(:)' y(1)];
for i = 1:length(x)
    edges(i).x = [xE(i) xE(i+1)];
    edges(i).y = [yE(i) yE(i+1)];

    edges(i).N = ceil(sqrt(diff(edges(i).x)^2 + diff(edges(i).y)^2)/0.4);
    X = linspace(edges(i).x(1),edges(i).x(2),edges(i).N);
    Y = linspace(edges(i).y(1),edges(i).y(2),edges(i).N);
    % Add neighbouring pixels as well. Creates duplicated, but also
    % ensures, that pixels where only a small corner is intersected is also
    % included
    X = X'+[-1 0 0 0 1];
    Y = Y'+[0 -1 0 1 0];
    
    edges(i).X = X(:)';
    edges(i).Y = Y(:)';
    edges(i).pixels = unique(round([edges(i).X; edges(i).Y])','rows')';
    edges(i).edge = i*ones(1,size(edges(i).pixels,2));
end

allEdgePixels = [edges.pixels];
[uniqueEdgePixels, ~, uniqueEdgePixelIdx] = unique(allEdgePixels','rows');
edgePixelsEdgeOrigin = [edges.edge];

% Loop through edge pixels
for p = 1:size(uniqueEdgePixels,1)
    idx = find(uniqueEdgePixelIdx == p);
    if (uniqueEdgePixels(p,1) > 0) && (uniqueEdgePixels(p,1) <= n) && (uniqueEdgePixels(p,2) > 0) && (uniqueEdgePixels(p,2) < m)
        edgePixelXs = uniqueEdgePixels(p,1) + [-0.5 -0.5 0.5 0.5 -0.5];
        edgePixelYs = uniqueEdgePixels(p,2) + [-0.5 0.5 0.5 -0.5 -0.5];

        points = [edgePixelXs(1:end-1)' edgePixelYs(1:end-1)'];

        % Loop through all edges in polygon
        for e = 1:length(idx)
            % Look up edge
            edge = edges(edgePixelsEdgeOrigin(idx(e)));

            % Grab xy-coordinates of the end points of the egde / line segment
            x1 = edge.x(1);
            x2 = edge.x(2);
            y1 = edge.y(1);
            y2 = edge.y(2);

            % Add edge end points to list of points, if they are inside pixel
            isInPoly = inpolygon([x1;x2], [y1;y2], edgePixelXs, edgePixelYs);
            if (isInPoly(1))
                points(end+1,:) = [x1 y1];
            end
            if (isInPoly(2))
                points(end+1,:) = [x2 y2];
            end

            % Loop through all edges of the pixel
            for c = 1:(length(edgePixelXs)-1)

                % Grab the xy-coordinates of the edge of the pixel
                x3 = edgePixelXs(c);
                x4 = edgePixelXs(c+1);
                y3 = edgePixelYs(c);
                y4 = edgePixelYs(c+1);

                % Calculate denominator to check if lines are parallel
                denom = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4);

                % Lines are parallel, if denom = 0. Assume lines are paralle if
                % denom is small.
                if (abs(denom) > 10^-3)
                    t = ((x1-x3)*(y3-y4) - (y1-y3)*(x3-x4)) / denom;
                    u = -((x1-x2)*(y1-y3) - (y1-y2)*(x1-x3)) / denom;

                    % Check if intersection is on both line segments
                    if (t >= 0) && (t <= 1) && (u >= 0) && (u <= 1)
                        % Calculate intersection point based on both line
                        % segments
                        Pxt = x1 + t*(x2-x1);
                        Pyt = y1 + t*(y2-y1);
                        Pxu = x3 + u*(x4-x3);
                        Pyu = y3 + u*(y4-y3);
                        Px = mean([Pxt Pxu]);
                        Py = mean([Pyt Pyu]);

                        % Add intersection to list of points for pixel
                        points(end+1,:) = [Px Py];
                    end
                end
            end
        end

        % Remove doublicated points
        points = unique(points,'rows');

        % Divide pixel into triangles based on corners, line-edge intersections
        % and vertices inside pixel.
        TRI = delaunay(points(:,1),points(:,2));

        % Loop through all triangles of pixel and add their area to the
        % weighted mask if the respective triangle center of mass is within the
        % original specified polygon.
        pixelPolygonArea = 0;
        for t = 1:size(TRI,1)
            triPoints = points(TRI(t,:),:);
            CM = mean(triPoints,1);
            if (inpolygon(CM(1),CM(2),x,y))
                a = sqrt((triPoints(1,1)-triPoints(2,1))^2 + (triPoints(1,2)-triPoints(2,2))^2);
                b = sqrt((triPoints(2,1)-triPoints(3,1))^2 + (triPoints(2,2)-triPoints(3,2))^2);
                c = sqrt((triPoints(3,1)-triPoints(1,1))^2 + (triPoints(3,2)-triPoints(1,2))^2);
                s = (a+b+c)/2;
                A = sqrt(s*(s-a)*(s-b)*(s-c));
                pixelPolygonArea = pixelPolygonArea + A;
            end

        end

        % Update current pixel of weighted mask
        MW(uniqueEdgePixels(p,2),uniqueEdgePixels(p,1)) = pixelPolygonArea;
    end
end

end

