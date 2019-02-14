function [ otsuTh ] = otsuThreshold( values )
%OTSUTHRESHOLD Summary of this function goes here
%   Detailed explanation goes here

% Normalize values to [0;1]
values = double(values);
offset = min(values);
scale = max(values)-min(values);
valuesNormalized = (values - offset)/scale;

% Obtain normalized threshold
otsuThNormalized = graythresh(valuesNormalized);

% Scale and offset threshold to match original values
otsuTh = otsuThNormalized * scale + offset;

end
