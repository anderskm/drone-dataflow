function [height] = heightFromPlane(X, Y, Z, planeParams)
%PLANE2HEIGHT Summary of this function goes here
%   Detailed explanation goes here
% x*a+y*b+z*c+d = 0
% where planeParams = [a b c d]
% z0 = -(d + x*a + y*b)/c 

height = Z+(planeParams(4) + X*planeParams(1) + Y*planeParams(2))/planeParams(3);

end
