function [ rect ] = poly2rect( varargin )
%POLY2RECT Polygon to size and position rectangle
% Convert at polygon to a size and position rectangle, which contains all
% the vertices in the polygon.
%
% USAGE:
%   rect = poly2rect(XY)
%   rect = poly2rect(X,Y)
%
% INPUTS:
%   XY  : 2xN matrix. Each column represents a vertex in the polygon. First
%         row is X-coordinates. Second row is Y-coordinates.
%   X   : 1xN or Nx1 vector of X-coordinates.
%   Y   : 1xN or Nx1 vector of Y-coordinates.
%
% OUTPUTS:
%   rect    : rect = [xmin ymin width height], where width is the xmax-xmin
%             and height is ymax-ymin.
%
% See also: imcrop

    if nargin == 1
        XY = varargin{1};
        X = XY(1,:);
        Y = XY(2,:);
    elseif nargin == 2
        X = varargin{1};
        Y = varargin{2};
    end

    xmin = min(X(:));
    xmax = max(X(:));
    ymin = min(Y(:));
    ymax = max(Y(:));

    rect = [xmin ymin xmax-xmin ymax-ymin];

end

