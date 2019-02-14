function [ kernel ] = generateMarkerKernel( order, kernelsize )
%GENERATEMARKERKERNEL Generate symmetric marker kernel
%
%
% Author:     Henrik Midtiby, University of Southern Denmark
% Adapted by: Anders Krogh Mortensen, Aarhus University

    stepsize = 2 / (kernelsize-1);
    temp1 = meshgrid(-1:stepsize:1);
    kernel = temp1 + 1i*temp1';

    % Normalize the magnitude to one at all positions
    kernel = kernel./abs(kernel);
    kernel(isnan(kernel)) = 1;


    kernel = kernel.^order;

    % Set values outside kernelsize to zero
    kernel(sqrt(temp1.^2+(temp1.^2)')>sqrt(1)) = 0;

end

