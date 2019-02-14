function [ settings ] = loadDefaultMarkerDetectionSettings( flightGSD, resizeGSD )
%LOADDEFAULTMARKERDETECTIONSETTINGS Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 2)
        resizeGSD = flightGSD;
    end;
    
    settings.flight.GSD = flightGSD;

    % Setup settings for marker design (should be fixed)
    settings.markerDesign.order = 2;
    settings.markerDesign.relativeRadius = 0.35;
    settings.markerDesign.numBits = 3;
    settings.markerDesign.bitMargin = 1;
    settings.markerDesign.gammaLevels = 5;
    settings.markerDesign.linePattern.baseWidth = 0.12;
    settings.markerDesign.linePattern.scaleFactor = 0.0614823;
    settings.markerDesign.linePattern.lines1Power = 0:6;
    settings.markerDesign.linePattern.lines2Power = 7:19;
    settings.markerDesign.realSize = 100; % cm
    
    % Setup settings for pre-processing
    settings.preprocessing.undistort = false; % Obsolete?

    % Setup settings for detection / find marker candidates (can be iterated
    % over)
    settings.markerDetection.resizeGSD = resizeGSD;
    settings.markerDetection.diameter = settings.markerDesign.realSize*(2*settings.markerDesign.relativeRadius)/settings.markerDetection.resizeGSD;
    settings.markerDetection.kernel = generateMarkerKernel( settings.markerDesign.order, settings.markerDetection.diameter );
    settings.markerDetection.numPeaks = 3;
    settings.markerDetection.suppressionRegion = 2*settings.markerDetection.diameter*ones(1,2);
    settings.markerDetection.responseThreshold = 0; % Obsolete?

    % Setup settings for finding marker corners
    settings.markerCornerDetection.angularResolution = 1; % [1 2 3 5 6 9 10 15 18 30 45 90] % Must be a divisor to 90
    settings.markerCornerDetection.stdThreshold = 0.5; % Obsolete
    settings.markerCornerDetection.filterResponseThreshold = 0; %Obsolete?

    % Setup settings for classifier
    settings.markerClassification.classifierType = 'LinearManual';
    settings.markerClassification.a = -48.4646655442861;
    settings.markerClassification.b = 9.49136861988256;
    settings.markerClassification.normalizeResponse = true;
    

end

