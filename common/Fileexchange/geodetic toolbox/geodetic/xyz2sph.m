function [az,va,d]=xyz2sph(x,y,z)
% XYZ2SPH  Converts Cartesian coordinates in a left-handed
%   (local geodetic) system to spherical coordinates.
%   Vectorized.  See also SPH2XYZ.
% Version: 7 Jul 96
% Usage:   [az,va,d]=xyz2sph(x,y,z)
% Input:   x \
%          y  > vectors of cartesian coordinates (linear units)
%          z /
% Output:  az - vector of azimuths (radians)
%          va - vector of vertical angles (radians)
%          d  - vector of distances (linear units)

% Copyright (c) 2011, Michael R. Craymer
% All rights reserved.
% Email: mike@craymer.com

if nargin ~= 3
  warning('Incorrect number of input arguments');
  return
end

d=sqrt(x.*x+y.*y+z.*z);
az=atan2(y,x);
%az=atan(y./x);
%az=az+(x<0)*pi;     % 2nd & 3rd quad
%az=az+(az<0)*2*pi;  % 4th quad
va=asin(z./d);