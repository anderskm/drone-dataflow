function [outputArg1,outputArg2] = estimateLocalBias( mapRef, mapRefInfo, ROIs, biasFunc)
%ESTIMATELOCALBIAS Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 4)
        biasFunc = @(x) mean(x);
    end
    
    

end

