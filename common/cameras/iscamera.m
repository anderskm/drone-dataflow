function [TF] = iscamera(imageFolder, imageFile, cameraModel)
%ISCAMERA Summary of this function goes here
%   Detailed explanation goes here

    % Check if camera mode has any required exif tags
    if (isfield(cameraModel,'requiredExifTags'))
        % Get required exif tags and their expected values
        reqExifTags = fieldnames(cameraModel.requiredExifTags)';
        reqExifTagValues = cell(size(reqExifTags));
        for e = 1:length(reqExifTags)
            reqExifTagValues{e} = cameraModel.requiredExifTags.(reqExifTags{e});
        end

        % Extract required exif tags from images
        [ outputCsvFilename ] = exiftoolExtractTagsToCSV(reqExifTags, imageFolder, imageFile, 'exifTags_cameraModel.csv', 0 );
        [ reqExifTagStruct ] = readExifToolCSV( fullfile(imageFolder, outputCsvFilename), 0 );

        % Parse exif tags of first image to see if they match the expected
        TF = zeros(size(reqExifTags),'logical');
        for e = 1:length(reqExifTags)
            if (isfield(reqExifTagStruct(1),reqExifTags{e}))
                exifTagValue = reqExifTagStruct(1).(reqExifTags{e});
                TF(e) = strcmp(reqExifTagValues{e}, exifTagValue);
            else
                TF(e) = 0;
            end
        end
    else
        % If the camera model does not have any required exif tags, return
        % false.
        TF = false;
    end

end

