function [ Ry ] = rotmaty( angle )
%ROTMATX Summary of this function goes here
%   Detailed explanation goes here

    Ry = [cosd(angle)     0     sind(angle);
          0               1     0;
          -sind(angle)    0     cosd(angle)];

end

