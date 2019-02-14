function [cameraModel] = detectCameraModel(imageFolder, imageFile)
%DETECTCAMERAMODEL Summary of this function goes here
%   Detailed explanation goes here

disp('Attempting to detect camera model...');
cameraModel = []; % Set default value. If the camera model could not be detected, return an empty array

cameraModels = listCameraModels( );
isCameraModels = zeros(size(cameraModels),'logical');
for c = 1:length(cameraModels)
    [ camera ] = loadCamera( cameraModels{c});
    isCameraModels(c) = all(iscamera(imageFolder, imageFile, camera));
    disp([num2str(all(isCameraModels(c))) ' ' cameraModels{c}]);
end

if (sum(isCameraModels) < 1)
    disp('No known camera models matches images.');
elseif (sum(isCameraModels) == 1)
    % Only one camera model matches
    cameraModel = cameraModels{isCameraModels};
    disp(['Camera model detected: ' cameraModels{isCameraModels}]);
else
    disp(['Too many (' num2str(sum(isCameraModels)) ') camera models matches images.']);
end

end

