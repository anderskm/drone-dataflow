function [ p ] = linePlaneIntersection( n, p0, l0, l )
%LINEPLANEINTERSECTION Summary of this function goes here
%   Detailed explanation goes here

ln = dot(l,n);

d = dot((p0-l0),n)/ln;

p = l0+d*l;

end

