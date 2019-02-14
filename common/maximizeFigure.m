function [ figHandle ] = maximizeFigure( figHandle, taskbarHeight )
%MAXIMIZEFIGURE Summary of this function goes here
%   Detailed explanation goes here

if (nargin < 1)
    figHandle = gcf;
end;
if (nargin < 2)
    taskbarHeight = 39;
end;

set(figHandle, 'outerposition', get(0, 'Screensize') - [0 -taskbarHeight 0 taskbarHeight]);


end

