function [markers, GCPs] = assignGCPs(markers, GCPs, Pprior)
%ASSIGNGCPS Summary of this function goes here
%   Detailed explanation goes here

        GCPpositions = [[GCPs.UTMEast]' [GCPs.UTMNorth]'];

        stddev = 12.9; % Magic number describing the stddev of detections near a GCP
        markerIDs = unique([markers.ID]);
        P = zeros(length(markerIDs),length(GCPs));
        for g = 1:length(GCPs)
%             allMarkerPos = reshape([markers.UAVPosition]',3,[])';
%             allMarkerPos = allMarkerPos(:,1:2);

            for i = 1:length(markerIDs)
                thisMarkerPos = reshape([markers([markers.ID] == markerIDs(i)).UAVPosition]',3,[])';
                thisMarkerPos = thisMarkerPos(:,1:2);

                gaussDist = 1./(stddev*sqrt(2*pi))*exp(-(sum((thisMarkerPos-GCPpositions(g,:)).^2,2)./(2*stddev)));
                P(i,g) = sum(gaussDist);
            end
        end
        
        if (nargin < 3)
            Pprior = ones(size(P));
        end
        
%         disp(Pprior)
        
        P = P.*Pprior;
        
        [~, GCPmarkerIDsIdx] = max(P,[],1);
        GCPids = markerIDs(GCPmarkerIDsIdx);
        
%         [alphabet(1:length(GCPs));num2cell(markerIDs(GCPmarkerIDsIdx))]
        
        for i = 1:length(GCPs)
            GCPs(i).ID = GCPs(i).name;
%             GCPs(i).name = alphabet{i};
        end
        
        for m = 1:length(markerIDs)
            gcpIdx = find(GCPids == markerIDs(m));
            markerIdx = find(and([markers.ID] == markerIDs(m),[markers.isMarker]));
%             thisMarkerPos = reshape([markersReviewed([markersReviewed.ID] == markerIDs(m)).UAVPosition]',3,[])';
            thisMarkerPos = reshape([markers(markerIdx).UAVPosition]',3,[])';
            thisMarkerPos = thisMarkerPos(:,1:2);
            GCPpos = GCPpositions(gcpIdx,:);
            distances = pdist2(thisMarkerPos,GCPpos,'euclidean');
            [~,marker2gcpIdx] = min(distances,[],2);
            for r = 1:length(markerIdx)
                idx = markerIdx(r);
                if (~isempty(gcpIdx))
                    markers(idx).name = GCPs(gcpIdx(marker2gcpIdx(r))).name;
                    markers(idx).GCPidx = gcpIdx(marker2gcpIdx(r));
                else
                    warning('Marker not matched to GCP!');
                    markers(idx).GCPidx = [];
                end
            end
        end

end

