function [featVal] = coverage_ExGR(I, m, T)
% Extimate crop coverage from an RGB image based on the difference in
% excess green (ExG) and excess red (ExR).
%
% The feature is based on the following scientific publications:
% Camargo Neto, J., 2004. A Combined Statistical—Soft Computing Approach 
%   for Classification and Mapping Weed Species in Minimum Tillage Systems.
%   PhD Dissertation, University of Nebraska, Lincoln, NE
% Meyer, G. E., and Neto, J. C., 2008. Verification of color vegetation 
%   indices for automated crop imaging applications. Computers and
%   Electronics in Agriculture, 2008, vol. 63, pp 282-293.


    if (size(I,3) >= 3)
        I = double(I(:,:,1:3));
        r = I(:,:,1)./sum(I,3);
        g = I(:,:,2)./sum(I,3);
        b = I(:,:,3)./sum(I,3);
        
        ExG = 2*g-r-b;
        ExR = 1.4*r-g;
        ExGR = ExG-ExR;
        
        coverage = sum(ExGR(m > 0) > 0)/sum(m(:) > 0);
        featVal = coverage;
    else
        featVal = NaN;
    end

end
