function [ Rz ] = rotmatz( angle )
%ROTMATX Summary of this function goes here
%   Detailed explanation goes here

    Rz = [cosd(angle)     -sind(angle)   0;
          sind(angle)    cosd(angle)   0;
          0               0             1];

end

