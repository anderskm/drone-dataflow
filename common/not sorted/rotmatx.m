function [ Rx ] = rotmatx( angle )
%ROTMATX Summary of this function goes here
%   Detailed explanation goes here

    Rx = [1     0               0
          0     cosd(angle)    -sind(angle);
          0     sind(angle)    cosd(angle)];

end

