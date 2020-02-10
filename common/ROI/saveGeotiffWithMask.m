function saveGeotiffWithMask( outputFilepath, Icut, Imask, mapTransformationROI, GeoKeyDirectoryTag, varargin) % GeoKeyDirectoryTag
%SAVEGEOTIFFWITHMASK Summary of this function goes here
%   Detailed explanation goes here

% Sources:
% http://www.awaresystems.be/imaging/tiff/tifftags/search.html?q=geotiff&Submit=Find+Tags
% http://se.mathworks.com/help/matlab/ref/tiff-class.html#btqyn4b-3
% http://se.mathworks.com/help/matlab/import_export/exporting-to-images.html#br_c_iz-1
% https://se.mathworks.com/matlabcentral/newsreader/view_thread/309997
% http://duff.ess.washington.edu/data/raster/drg/docs/geotiff.txt

% ToDo:
% - Move mask to varargin. If not specified, make mask covering entire
% image
% - 

    % Parse inputs
    p = parseInputs(varargin{:});
%     refMap = p.Results.refMap;
%     refMapTrans = p.Results.refMapTrans;
%     storeROIs = p.Results.storeROIs;
%     verbose = p.Results.verbose;
%     numDisplaySpaces = (verbose-1)*3;
    
    saveAsPseudoColor = p.Results.saveAsPseudoColor;
    pseudoColormap = p.Results.pseudoColormap;
    range = p.Results.range;
    mapMin = range(1);
    mapMax = range(2);
    
    isIndex = false;
    isRGB = false;

    if (size(Icut,3) == 1) % Assume index map
        Icut2 = Icut;
        isIndex = true;
    elseif (size(Icut,3) == 2) % Assume index map + alpha
        Icut2 = Icut(:,:,1);
        isIndex = true;
    elseif (size(Icut,3) == 3) % Assume RGB
        Icut2 = im2double(Icut);
        isRGB = true;
        saveAsPseudoColor = false;
    elseif (size(Icut,3) == 4) % Assume RGB + alpha
        Icut2 = im2double(Icut(:,:,1:3));
        isRGB = true;
        saveAsPseudoColor = false;
    else
        error(['Size of 3rd dimension handle is unknown. Image size  [' num2str(size(Icut)) ']'])
    end
    
    % Hack. Wrong field names will cause error. "Unknown" is the only known
    % wrong field name.
    if (isfield(GeoKeyDirectoryTag,'Unknown'))
        GeoKeyDirectoryTag = rmfield(GeoKeyDirectoryTag,'Unknown');
    end
    
    if (isIndex) && (saveAsPseudoColor)
        saveGeotiff_index_pseudo( outputFilepath, Icut2, Imask, mapTransformationROI, GeoKeyDirectoryTag, pseudoColormap, mapMin, mapMax);
    elseif (isIndex) && (~saveAsPseudoColor)
        saveGeotiff_index_raw( outputFilepath, Icut2, Imask, mapTransformationROI, GeoKeyDirectoryTag);
    elseif (isRGB)
        saveGeotiff_rgb_raw( outputFilepath, Icut2, Imask, mapTransformationROI, GeoKeyDirectoryTag);
    else
        warning('Using old function...');
        if (saveAsPseudoColor)

            if (size(pseudoColormap,1) < 256)
                warning('Pseudo colormap size has less that 256 colors. Use 256 colors for best results. E.g. parula(256), jet(256) or hot(256)');
            end;

            if (isnan(mapMin))
                warning('Minimum value for pseudo colors not specified. See range parameter. Using minimum from supplied image.')
                mapMin = max(min(Icut2(:)),0);

            end;
            if (isnan(mapMax))
                warning('Maximum value for pseudo colors not specified. See range parameter. Using maximum from supplied image.')
                mapMax = max(Icut2(:));
            end;

    %         if (ndims(Icut) == 2)
    %             Icut2 = (Icut - mapMin)/(mapMax - mapMin);
    %             Icut2 = ind2rgb(round(Icut2*((2^8)-1)), parula(2^8));
    %         else
    %             error(['Image have too many dimensions. Could not convert to pseudo colors. Image size must be [N M 1], but it was [' num2str(size(Icut)) ']']);
    %         end;

            Icut2 = (double(Icut2) - double(mapMin))/(double(mapMax) - double(mapMin));
            Icut2 = ind2rgb(round(Icut2*((2^8)-1)), parula(2^8));
        end

        IcutOut = cat(3, Icut, single(Imask));

        % Use MATLAB built-in geotiffwriter to create a temporary geotiff with
        % the correct geotags
        geotiffwrite(outputFilepath, uint8(IcutOut*((2^8)-1)), mapTransformationROI, 'GeoKeyDirectoryTag', GeoKeyDirectoryTag);
    %     geotiffwrite(outputFilepath, uint8(IcutOut*((2^8)-1)), mapTransformationROI);

        % Read geotags from temprary geotiff
        t = Tiff(outputFilepath,'r');
        try
            GeoASCIIParamsTag = t.getTag('GeoASCIIParamsTag');
            GeoKeyDirectoryTag = t.getTag('GeoKeyDirectoryTag');
            ModelPixelScaleTag = t.getTag('ModelPixelScaleTag');
            ModelTiepointTag = t.getTag('ModelTiepointTag');
        catch ex
            t.close()
            rethrow(ex)
        end;
        t.close();

        % Concatenate mask to image and scale both to range [0;255]
        IcutOut = uint8(cat(3, Icut2*((2^8)-1), single(Imask)*255));

        % Get size of image
        numRows = size(IcutOut,1);
        numCols = size(IcutOut,2);

        % Write geotiff manually with mask as alpha layer
        t = Tiff(outputFilepath,'w');
        try
            t.setTag('Photometric',Tiff.Photometric.RGB);
            t.setTag('Compression',Tiff.Compression.None);
            t.setTag('BitsPerSample',8);
            t.setTag('SamplesPerPixel',size(IcutOut,3));
            t.setTag('SampleFormat',Tiff.SampleFormat.UInt);
            t.setTag('ExtraSamples',Tiff.ExtraSamples.Unspecified);
            t.setTag('ImageLength',numRows);
            t.setTag('ImageWidth',numCols);
            % Add geotags
            t.setTag('GeoASCIIParamsTag', GeoASCIIParamsTag);
            t.setTag('GeoKeyDirectoryTag', GeoKeyDirectoryTag);
            t.setTag('ModelPixelScaleTag',ModelPixelScaleTag);
            t.setTag('ModelTiepointTag',ModelTiepointTag);
            t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
            % Write image
            t.write(IcutOut);
        catch ex
            t.close()
            rethrow(ex)
        end;
        t.close();
    end
end

function p = parseInputs(varargin)
    p = inputParser();
    addParameter(p,'saveAsPseudoColor',true,@(x)validateattributes(x, {'logical'},{'nonempty'}));
    addParameter(p,'pseudoColormap', parula(256));
    addParameter(p,'range',[NaN NaN],@(x)validateattributes(x, {'numeric'},{'nonempty'}));
    parse(p, varargin{:}); 
end

function saveGeotiff_index_pseudo( outputFilepath, Icut, Imask, mapTransformationROI, GeoKeyDirectoryTag, pseudoColormap, mapMin, mapMax)

    Icut2 = Icut;
    % Scale image
    Icut2 = (double(Icut2) - double(mapMin))/(double(mapMax) - double(mapMin));
%     Icut2 = ind2rgb(round(Icut2*((2^8)-1)), parula(2^8));
    Icut2 = ind2rgb(round(Icut2*((2^8)-1)), pseudoColormap);

    IcutOut = cat(3, Icut, single(Imask));

    % Use MATLAB built-in geotiffwriter to create a temporary geotiff with
    % the correct geotags
    geotiffwrite(outputFilepath, uint8(IcutOut*((2^8)-1)), mapTransformationROI, 'GeoKeyDirectoryTag', GeoKeyDirectoryTag);
%     geotiffwrite(outputFilepath, uint8(IcutOut*((2^8)-1)), mapTransformationROI);
    
    % Read geotags from temprary geotiff
    t = Tiff(outputFilepath,'r');
    try
        GeoASCIIParamsTag = t.getTag('GeoASCIIParamsTag');
        GeoKeyDirectoryTag = t.getTag('GeoKeyDirectoryTag');
        ModelPixelScaleTag = t.getTag('ModelPixelScaleTag');
        ModelTiepointTag = t.getTag('ModelTiepointTag');
    catch ex
        t.close()
        rethrow(ex)
    end;
    t.close();

    % Concatenate mask to image and scale both to range [0;255]
    IcutOut = uint8(cat(3, Icut2*((2^8)-1), single(Imask)*255));
    
    % Get size of image
    numRows = size(IcutOut,1);
    numCols = size(IcutOut,2);

    % Write geotiff manually with mask as alpha layer
    t = Tiff(outputFilepath,'w');
    try
        t.setTag('Photometric',Tiff.Photometric.RGB);
        t.setTag('Compression',Tiff.Compression.None);
        t.setTag('BitsPerSample',8);
        t.setTag('SamplesPerPixel',size(IcutOut,3));
        t.setTag('SampleFormat',Tiff.SampleFormat.UInt);
        t.setTag('ExtraSamples',Tiff.ExtraSamples.Unspecified); % Try Tiff.ExtraSamples.UnassociatedAlpha
        t.setTag('ImageLength',numRows);
        t.setTag('ImageWidth',numCols);
        % Add geotags
        t.setTag('GeoASCIIParamsTag', GeoASCIIParamsTag);
        t.setTag('GeoKeyDirectoryTag', GeoKeyDirectoryTag);
        t.setTag('ModelPixelScaleTag',ModelPixelScaleTag);
        t.setTag('ModelTiepointTag',ModelTiepointTag);
        t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
        % Write image
        t.write(IcutOut);
    catch ex
        t.close()
        rethrow(ex)
    end;
    t.close();
end
function saveGeotiff_index_raw( outputFilepath, Icut, Imask, mapTransformationROI, GeoKeyDirectoryTag)

%     IcutOut = cat(3, Icut, single(Imask));

    % Use MATLAB built-in geotiffwriter to create a temporary geotiff with
    % the correct geotags
    geotiffwrite(outputFilepath, Icut, mapTransformationROI, 'GeoKeyDirectoryTag', GeoKeyDirectoryTag);
%     geotiffwrite(outputFilepath, uint8(IcutOut*((2^8)-1)), mapTransformationROI);
    
    % Read geotags from temprary geotiff
    t = Tiff(outputFilepath,'r');
    try
        GeoASCIIParamsTag = t.getTag('GeoASCIIParamsTag');
        GeoKeyDirectoryTag = t.getTag('GeoKeyDirectoryTag');
        ModelPixelScaleTag = t.getTag('ModelPixelScaleTag');
        ModelTiepointTag = t.getTag('ModelTiepointTag');
    catch ex
        t.close()
        rethrow(ex)
    end;
    t.close();

    % Concatenate mask to image and scale both to range [0;255]
    IcutOut = cat(3, single(Icut), single(Imask));
    
    % Get size of image
    numRows = size(IcutOut,1);
    numCols = size(IcutOut,2);

    % Write geotiff manually with mask as alpha layer
    t = Tiff(outputFilepath,'w');
    try
        t.setTag('Photometric',Tiff.Photometric.MinIsBlack);
        t.setTag('Compression',Tiff.Compression.None);
        t.setTag('BitsPerSample',32);
        t.setTag('SamplesPerPixel',size(IcutOut,3));
        t.setTag('SampleFormat',Tiff.SampleFormat.IEEEFP);
        t.setTag('ExtraSamples',Tiff.ExtraSamples.AssociatedAlpha);
        t.setTag('ImageLength',numRows);
        t.setTag('ImageWidth',numCols);
        % Add geotags
        t.setTag('GeoASCIIParamsTag', GeoASCIIParamsTag);
        t.setTag('GeoKeyDirectoryTag', GeoKeyDirectoryTag);
        t.setTag('ModelPixelScaleTag',ModelPixelScaleTag);
        t.setTag('ModelTiepointTag',ModelTiepointTag);
        t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
        % Write image
        t.write(IcutOut);
    catch ex
        t.close()
        rethrow(ex)
    end;
    t.close();

end

function saveGeotiff_rgb_raw( outputFilepath, Icut, Imask, mapTransformationROI, GeoKeyDirectoryTag)
    IcutOut = cat(3, Icut, single(Imask));

    % Use MATLAB built-in geotiffwriter to create a temporary geotiff with
    % the correct geotags
    geotiffwrite(outputFilepath, uint8(IcutOut*((2^8)-1)), mapTransformationROI, 'GeoKeyDirectoryTag', GeoKeyDirectoryTag);
%     geotiffwrite(outputFilepath, uint8(IcutOut*((2^8)-1)), mapTransformationROI);

    % Read geotags from temprary geotiff
    t = Tiff(outputFilepath,'r');
    try
        GeoASCIIParamsTag = t.getTag('GeoASCIIParamsTag');
        GeoKeyDirectoryTag = t.getTag('GeoKeyDirectoryTag');
        ModelPixelScaleTag = t.getTag('ModelPixelScaleTag');
        ModelTiepointTag = t.getTag('ModelTiepointTag');
    catch ex
        t.close()
        rethrow(ex)
    end;
    t.close();

    % Concatenate mask to image and scale both to range [0;255]
    IcutOut = uint8(cat(3, Icut*((2^8)-1), single(Imask)*255));

    % Get size of image
    numRows = size(IcutOut,1);
    numCols = size(IcutOut,2);

    % Write geotiff manually with mask as alpha layer
    t = Tiff(outputFilepath,'w');
    try
        t.setTag('Photometric',Tiff.Photometric.RGB);
        t.setTag('Compression',Tiff.Compression.None);
        t.setTag('BitsPerSample',8);
        t.setTag('SamplesPerPixel',size(IcutOut,3));
        t.setTag('SampleFormat',Tiff.SampleFormat.UInt);
        t.setTag('ExtraSamples',Tiff.ExtraSamples.UnassociatedAlpha);
        t.setTag('ImageLength',numRows);
        t.setTag('ImageWidth',numCols);
        % Add geotags
        t.setTag('GeoASCIIParamsTag', GeoASCIIParamsTag);
        t.setTag('GeoKeyDirectoryTag', GeoKeyDirectoryTag);
        t.setTag('ModelPixelScaleTag',ModelPixelScaleTag);
        t.setTag('ModelTiepointTag',ModelTiepointTag);
        t.setTag('PlanarConfiguration',Tiff.PlanarConfiguration.Chunky);
        % Write image
        t.write(IcutOut);
    catch ex
        t.close()
        rethrow(ex)
    end;
    t.close();
end