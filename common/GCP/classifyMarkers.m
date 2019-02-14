function [ markers ] = classifyMarkers( markers, settings )
%CLASSIFYMARKERS Summary of this function goes here
%   Detailed explanation goes here

    if (~isempty(markers))
        a = settings.markerClassification.a;
        b = settings.markerClassification.b;

        responses = abs([markers.response]);
        if (settings.markerClassification.normalizeResponse)
            responses = responses./numel(settings.markerDetection.kernel);
        end;

        cornerFilterResponseMax = [markers.cornerFilterResponseMax];
        cornerFilterResponseMean = [markers.cornerFilterResponseMean];
        cornerFilterResponseStd = [markers.cornerFilterResponseStd];
        cornerFilterResponse = (cornerFilterResponseMax - cornerFilterResponseMean)./cornerFilterResponseStd;

        if (strcmp(settings.markerClassification.classifierType,'LinearManual'))
            [markerClassification] = classifyMarkersLinearManual(responses, cornerFilterResponse, a, b);
        else
            error('Unknown classifier type.');
        end;


        markers = markers(markerClassification);
    end;
    
end

function [markerClassification] = classifyMarkersLinearManual(responses, cornerFilterResponse, a, b)
    classify = @(x1, x2) (a*x1+b - x2);

    markerClassification_tmp = classify(responses, cornerFilterResponse);
    markerClassification = logical(zeros(size(markerClassification_tmp)));
    markerClassification(markerClassification_tmp < 0) = 1;
    
end
