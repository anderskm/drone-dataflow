function haralick_mean = haralick(I, Imask, haralick_feature, numLevels)
%HARALICK Summary of this function goes here
%   Detailed explanation goes here
    global intermediate_results;
    if (nargin < 4)
        numLevels = 8;
    end
    
    haralick_features = {'Energy','Contrast','Correlation','Variance','Homogeneity','SumAverage','SumVariance','SumEntropy','Entropy','DiffVariance','DiffEntropy','InfoMeasCorr1','InfoMeasCorr2','MaxCorrCoef'};
    if ~any(strcmp(haralick_features, haralick_feature))
        error('haralick:unknownFeature', ['Unknown Haralick feature name. Please use one of the following:\n' strjoin(haralick_features,'; ')])
    end
    if ~any(strcmp(haralick_feature, haralick_features([7, 9, 10, 13, 14])))
        % TODO: Add warning, when using one of the non-checked features
    end

    % Co-occurance matrices have not already been calculated, skip check on
    % and conversion of input image
    if (~isfield(intermediate_results, 'glcms_000') || ~isfield(intermediate_results, 'glcms_045') || ~isfield(intermediate_results, 'glcms_090') || ~isfield(intermediate_results, 'glcms_135'))
        if (size(I,3) == 1)
            Igray = I;
        elseif (size(I,3) == 3)
            Igray = im2double(rgb2gray(I));
        elseif (size(I,3) == 4)
            Igray = im2double(rgb2gray(I(:,:,1:3)));
        else
            % Throw error
            error('haralick:unknownImageChannels',['Unknown number of image channels (' num2str(size(I,3)) '). Expected 1, 3 or 4.']);
        end
        Igray(~Imask) = NaN;
    end

    % Temporarily turn off warnings, as graycomatrix will give warning for
    % NaN values, which will most likely always be present.
    warnStruct = warning();
    warning off;
    if isfield(intermediate_results, 'glcms_000')
        glcms_000 = intermediate_results.glcms_000;
    else
        glcms_000 = graycomatrix(Igray, 'Offset', [0 1], 'Symmetric',true, 'NumLevels', numLevels);
        intermediate_results.glcms_000 = glcms_000;
    end
    if isfield(intermediate_results, 'glcms_045')
        glcms_045 = intermediate_results.glcms_045;
    else
        glcms_045 = graycomatrix(Igray, 'Offset', [-1 1], 'Symmetric',true, 'NumLevels', numLevels);
        intermediate_results.glcms_045 = glcms_045;
    end
    if isfield(intermediate_results, 'glcms_090')
        glcms_090 = intermediate_results.glcms_090;
    else
        glcms_090 = graycomatrix(Igray, 'Offset', [-1 0], 'Symmetric',true, 'NumLevels', numLevels);
        intermediate_results.glcms_090 = glcms_090;
    end
    if isfield(intermediate_results, 'glcms_135')
        glcms_135 = intermediate_results.glcms_135;
    else
        glcms_135 = graycomatrix(Igray, 'Offset', [-1 -1], 'Symmetric',true, 'NumLevels', numLevels);
        intermediate_results.glcms_135 = glcms_135;
    end
    warning(warnStruct); % Reset warnings to previous state.
    
    % Use Matlab implementation if available
    if any(strcmp(haralick_feature, {'Contrast','Correlation','Energy','Homogeneity'}))
        haralick_000 = graycoprops(glcms_000, haralick_feature);
        haralick_045 = graycoprops(glcms_045, haralick_feature);
        haralick_090 = graycoprops(glcms_090, haralick_feature);
        haralick_135 = graycoprops(glcms_135, haralick_feature);
    
        haralick_all = [haralick_000.(haralick_feature), haralick_045.(haralick_feature), haralick_090.(haralick_feature), haralick_135.(haralick_feature)];
        haralick_mean = mean(haralick_all);
    else % Use function from FileExchange otherwise
        haralick_feat_idx = find(strcmp(haralick_feature, haralick_features));
        haralick_000 = haralickTextureFeatures(glcms_000, haralick_feat_idx);
        haralick_045 = haralickTextureFeatures(glcms_045, haralick_feat_idx);
        haralick_090 = haralickTextureFeatures(glcms_090, haralick_feat_idx);
        haralick_135 = haralickTextureFeatures(glcms_135, haralick_feat_idx);

        haralick_all = [haralick_000, haralick_045, haralick_090, haralick_135];
        haralick_mean = mean(haralick_all(haralick_feat_idx,:), 2);
    end

        
end

