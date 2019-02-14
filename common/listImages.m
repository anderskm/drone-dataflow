function [ images, imageFolder, imgExt] = listImages( imageFolder, imageExtensions)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

imageExtensionsDefault = {'tif','tiff','jpg'};
if (nargin < 2)
    imageExtensions = imageExtensionsDefault;
end

if (~iscell(imageExtensions))
    error('imageExtensions must be a cell array, even if it only contains one valid extension.');
end

% Prompt user for input folder
if (nargin < 1)
    imageFolder = uigetdir(pwd,'Select image folder');
    if (imageFolder == 0)
        error('Folder selection cancelled by user.');
    end
end

disp(['      Image folder: ' imageFolder]);
disp(['      Looking for images with extensions: ' cell2mat(cellfun(@(x) [x ', '], imageExtensions,'UniformOutput',false))]);
imageCounts = zeros(1,length(imageExtensions));
images = cell(1, length(imageExtensions));
for i = 1:length(imageExtensions)
    images{i} = dir(fullfile(imageFolder,['*.' imageExtensions{i}]));
    imageCounts(i) = length(images{i});
    disp(['         ' imageExtensions{i} ' files detected: ' num2str(imageCounts(i))]);
end;
[~, maxIdx] = max(imageCounts);
disp(['         Most ' imageExtensions{maxIdx} ' files detected. Selecting ' imageExtensions{maxIdx} '-images for further processing.'])
images = images{maxIdx};
imgExt = imageExtensions{maxIdx};
disp(['      Detected files: ' num2str(length(images))]);

% Check if multiple images are embedded
info = imfinfo(fullfile(imageFolder,images(1).name));
imagesPerFile = numel(info);
disp(['      Images per file: ' num2str(imagesPerFile)]);
images = repmat(images',imagesPerFile,1);
for i = 1:size(images,2)
    for k = 1:imagesPerFile
        images(k,i).imagesPerFile = imagesPerFile;
        images(k,i).imageIdx = k;
        [~, imgName,~] = fileparts(images(k,i).name);
        if (imagesPerFile > 1)
            images(k,i).outName = [imgName '_' num2str(k) '.' imgExt];
        else
            images(k,i).outName = images(k,i).name;
        end
    end
end
images = reshape(images,1,[]); % Reshape from 2D matrix to 1D vector

disp(['      Number of images: ' num2str(length(images))]);

end
