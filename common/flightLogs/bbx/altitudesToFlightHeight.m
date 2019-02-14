function [ flightHeight, groundLevel, flightLevel ] = altitudesToFlightHeight( altitude )
%ALTITUDESTOFLIGHTHEIGHT Summary of this function goes here
%   Detailed explanation goes here

    heightThreshold = otsuThreshold(altitude);

    lowAltitudes = altitude(altitude < heightThreshold);
    highAltitudes = altitude(altitude > heightThreshold);

    groundLevel = median(lowAltitudes);
    flightLevel = median(highAltitudes);

    flightHeight = flightLevel - groundLevel;

end

