function [ R ] = rotmatYPR( yaw, pitch, roll )
%ROTMATYPR Summary of this function goes here
%   Detailed explanation goes here

    R = [rotmaty(-roll)*rotmatx(pitch)*rotmatz(-yaw) [0 0 0]'; 0 0 0 1];
%     R = [rotmatz(-yaw)*rotmatx(pitch)*rotmaty(-roll) [0 0 0]'; 0 0 0 1];
%     R = [rotmaty(roll)*rotmatx(pitch)*rotmatz(yaw) [0 0 0]'; 0 0 0 1];

end
