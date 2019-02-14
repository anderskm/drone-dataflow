function saveMarkers( markers, folder )
%SAVEMARKERS Summary of this function goes here
%   Detailed explanation goes here

    save(fullfile(folder,'GCPs_in_images.mat'),'markers');

end

