function [ xo ] = rounda( xi, alpha )
%ROUNDA rounds using alpha as midpoint
%   Round numbers up or down using alpha as a midpoint/threshold.
%
% USAGE:
%   xo = round(xi, alpha)
%
% INPUTS:
%   xi      Scalar, vector or array which should be rounded.
%   alpha   "Midpoint" or threshold used for determining if a number should
%   be rounded up or down. 
%
% OUTPUTS:
%   xo      Rounded numbers. Same size as xi.
%
%  Formula:
%   
%          _
%         /  floor(x) if x-floor(x) < alpha 
%   xo = <
%         \_ ceil(x)  if x-floor(x) >= alpha
%          
%
% See also: round, floor, ceil

    xo = floor(xi);
    xr = ceil(xi);

    xCeilIdx = xi-xo >= alpha;
    xo(xCeilIdx) = xr(xCeilIdx);

end

