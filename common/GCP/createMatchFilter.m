function [ matchFilter, blobSize ] = createMatchFilter( diameter, relativeRadius, angularResolution )
%CREATEMATCHFILTER Summary of this function goes here
%   Detailed explanation goes here

% diameter = 16
% relativeRadius = 0.35
% angularResolution = 2;

angularSpan = sum([0 90] -atand(70/100));

getSigma = @(x) sqrt(-x^2/(2*log(0.01)));
getGauss = @(x,sigma) 1/(sqrt(2*pi)*sigma)*exp(-(x.^2)/(2*sigma^2));

cornerSide = diameter*(1-relativeRadius*2)/2/(relativeRadius*2);
diagCorner = round(sqrt(2)*cornerSide);

sigmaR = getSigma(diagCorner/2);
sigmaAng = getSigma(angularSpan/2);

% normDistR = 1/(sqrt(2*pi)*sigmaR)*exp(-(-diagCorner/2+0.5:1:diagCorner/2-0.5).^2/(2*sigmaR.^2))
% normDistR = 1/(sqrt(2*pi)*sigmaR)*exp(-(linspace(-diagCorner/2,diagCorner/2,diagCorner)).^2/(2*sigmaR.^2));
normDistR = getGauss(linspace(-diagCorner/2,diagCorner/2,diagCorner),sigmaR)./getGauss(0,sigmaR);

% normDistAng = 1/(sqrt(2*pi)*sigmaAng)*exp(-(-angularSpan/2:angularResolution:angularSpan/2).^2/(2*sigmaAng.^2))
% normDistAng = 1/(sqrt(2*pi)*sigmaAng)*exp(-(linspace(-angularSpan/2,angularSpan/2,angularSpan/angularResolution)).^2/(2*sigmaAng.^2));
normDistAng = getGauss(linspace(-angularSpan/2,angularSpan/2,angularSpan/angularResolution), sigmaAng)./getGauss(0,sigmaAng);

normDistRAng = normDistR'*normDistAng;
normDistRAng = normDistRAng./sum(normDistRAng(:));

matchFilter = zeros(size(normDistRAng,1),360/angularResolution);
matchFilter(:,1:size(normDistRAng,2)) = normDistRAng;
matchFilter(:,(1:size(normDistRAng,2)) + 90/angularResolution) = normDistRAng;
matchFilter(:,(1:size(normDistRAng,2)) + 180/angularResolution) = normDistRAng;
matchFilter(:,(1:size(normDistRAng,2)) + 270/angularResolution) = -3*normDistRAng;

blobSize = size(normDistRAng);

end

