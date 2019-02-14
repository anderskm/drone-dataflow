function extractROIsFromPix4dProject( p4dprojectfilepath, varargin)
%EXTRACTROI Summary of this function goes here
%   Detailed explanation goes here

    oldType = false; % Magic flag for selecting old type of map structure

    %% Parse inputs
    p = parseInputs(varargin{:});
    
    mapsStruct = p.Results.mapsStruct;
    
    refPix4dProject = p.Results.refPix4dProject;
    
    ROIs = p.Results.ROIs;
    ROIfile = p.Results.ROIfile;
    saveROIs = logical(p.Results.saveROIs);
    ROIcolormap = p.Results.ROIcolormap;
    
    featureHandles = p.Results.featureHandles;
    featureNames = p.Results.featureNames;
    if (isempty(featureNames))
        warning('Feature names not specified. Using feature handles as feature names.');
        featureNames = cellfun(@func2str,featureHandles,'UniformOutput',false);
    end;
    if (length(featureNames) ~= length(featureHandles))
        error('The number of feature names does not match the number of feature handles.');
    end;
    edges = p.Results.edges;
    
    verbose = p.Results.verbose;
    numDisplaySpaces = (verbose-1)*3;
        
    [projectPath, projectName, projectExt] = fileparts(p4dprojectfilepath);
    if (~isempty(refPix4dProject))
        [refProjectPath, refProjectName, ~] = fileparts(refPix4dProject);
    else
        refProjectPath = '';
        refProjectName = '';
    end;
    
    %% Handle maps
    
    mapsAutoSelectAll = false;
    if (strcmp(mapsStruct,'all'))
        mapsStruct = [];
        mapsAutoSelectAll = true;
    end
    
    % Handle no maps specified
    if (isempty(mapsStruct))
        dispts('No maps specified. Trying to locate all available maps.');
        mapsStruct = pix4dProject2mapsStruct(p4dprojectfilepath);
        
        % Select maps
        if (~mapsAutoSelectAll)
            [~, p4dName, p4dExt] = fileparts(p4dprojectfilepath);
            [mapSelection,ok] = listdlg('ListString', fullfile({mapsStruct.type}, {mapsStruct.shortName}), ...
                                     'SelectionMode','multiple', ...
                                     'ListSize',[300 300], ...
                                     'Name','Select maps for ROI extraction', ...
                                     'PromptString',{'Select one or more maps for ROI extraction from' ; ['Pix4D-project: ' p4dName p4dExt]}, ...
                                     'OKString','OK',...
                                     'CancelString','Cancel');
            if (strcmp(ok,'OK') || (ok == 1))
                mapsStruct = mapsStruct(mapSelection);
            else
                error('Sheet selection cancelled by user!');
            end
        else
            dispts('Auto selecting all detected maps.')
        end
        
    end;
    
    dispts('Maps:');
    disp({mapsStruct.fullName}');
    
    if (oldType)
        mapTypes = fieldnames(mapsStruct);
        numMaps = 0;
        for mt = 1:length(mapTypes)
            mapType = mapTypes{mt};
            maps = fieldnames(mapsStruct.(mapType));
            for m = 1:length(maps)
                numMaps = numMaps + 1;
            end;
        end;
    else
        mapTypes = unique({mapsStruct.type});
        numMaps = length(mapsStruct);
    end    

    %% Handle ROIs    
    if (isempty(ROIs))
        dispts('ROIs not specified. Attempting to read ROIfile.', numDisplaySpaces);
        if (isempty(ROIfile))
            dispts('No ROIfile specified. Prompt user to specify ROIfile.', numDisplaySpaces);
            [xlsROIfile, xlsROIfolder] = uigetfile({'*.xlsx';'*.xls'},'Select Excel spreadsheet with ROIs.', projectPath);
            ROIfile = fullfile(xlsROIfolder, xlsROIfile);
        end;
        
        % Select sheet in spreadsheet
        [ sheet, sheets ] = xlsSelectSheet( ROIfile );

        dispts(['ROI sheet              : ' sheet], numDisplaySpaces);

        % Load ROI file
        if (exist(ROIfile,'file'))
            [ ROIs, ROIheader ] = readROIfromXLS( ROIfile, sheet );
        else
            error(['ROI file does not exist: ' ROIfile]);
        end;
        
        dispts('ROI header:', numDisplaySpaces);
        disp(ROIheader)
        dispts('ROI areas:', numDisplaySpaces);
        disp(ROIheader.Area)
    end
    
    %%
    if (verbose)
        dispts('Extracting ROIs from project', numDisplaySpaces);
        dispts(['   Project name:        ' p4dprojectfilepath], numDisplaySpaces);
%         if (~isempty(refPix4dProject))
        dispts(['   Reference project:   ' refPix4dProject], numDisplaySpaces);
%         end
        dispts(['   Number of map types: ' num2str(length(mapTypes))], numDisplaySpaces);
        dispts(['   Number of maps:      ' num2str(numMaps)], numDisplaySpaces);
        if (~isempty(ROIfile))   
        dispts(['   ROI file:            ' ROIfile], numDisplaySpaces);
        end;
        dispts(['   Number of ROIs:      ' num2str(length(ROIs))], numDisplaySpaces);
        dispts(['   Feature names:       ' cell2mat(cellfun(@(x)([x ', ']),featureNames,'UniformOutput',false))], numDisplaySpaces);
        dispts(['   Feature handles:     ' cell2mat(cellfun(@(x)([x ', ']),cellfun(@func2str,featureHandles,'UniformOutput',false),'UniformOutput',false))], numDisplaySpaces);
        dispts(['   Edges (m):           ' num2str(edges(:)')]);
    end;
    
    %% Process maps
    if (verbose)
        dispts('Processing maps...', numDisplaySpaces);
    end;
    % Loop through each map type
    if (oldType)
        mapCounter = 0;
        mapTypes = fieldnames(mapsStruct);
        for mt = 1:length(mapTypes)
            mapType = mapTypes{mt};
            maps = fieldnames(mapsStruct.(mapType));
            for m = 1:length(maps)
                mapCounter = mapCounter + 1;
                map = mapsStruct.(mapTypes{mt}).(maps{m});
                % Setup path to map depending on mapType
                if strcmp(mapType, 'dsm')
                    mapPath = fullfile(projectPath, projectName, '3_dsm_ortho','1_dsm',[projectName '_' map '.tif']);
                    refMapPath = fullfile(refProjectPath, refProjectName, '3_dsm_ortho','1_dsm',[refProjectName '_' map '.tif']);
                elseif strcmp(mapType, 'mosaic')
                    mapPath = fullfile(projectPath, projectName, '3_dsm_ortho','2_mosaic',[projectName '_mosaic_' map '.tif']);
                    refMapPath = fullfile(refProjectPath, refProjectName, '3_dsm_ortho','2_mosaic',[refProjectName '_mosaic_' map '.tif']);
                elseif strcmp(mapType, 'reflectance')
                    mapPath = fullfile(projectPath, projectName, '4_index','reflectance',[projectName '_' map '.tif']);
                    refMapPath = fullfile(refProjectPath, refProjectName, '4_index','reflectance',[refProjectName '_mosaic_' map '.tif']);
                elseif strcmp(mapType, 'indices')
                    mapPath = fullfile(projectPath, projectName, '4_index','indices',map,[projectName '_index_' map '.tif']);
                    refMapPath = fullfile(refProjectPath, refProjectName, '4_index','indices',map,[refProjectName '_index_' map '.tif']);
                else
                    mapPath = '';
                    refMapPath = '';
                end;
                if (verbose)
                    dispts(['Map (' num2str(mapCounter) '/' num2str(numMaps) '): ' mapType '.' map '...'], numDisplaySpaces);
                end;
                % If map exists, proceed to extract ROIs from it
                if (exist(mapPath,'file'))
                    if (exist(refMapPath,'file')) && (~isempty(refPix4dProject))
                        ROIsExtracted = extractROIsFromGeotiff(mapPath, ROIs, 'refMapFile',refMapPath, 'featureHandles',featureHandles, 'featureNames',featureNames, 'saveROIs',saveROIs, 'ROIcolormap',ROIcolormap, 'edges', edges, 'Verbose',sign(verbose)*(verbose+1));
                    else
                        ROIsExtracted = extractROIsFromGeotiff(mapPath, ROIs, 'featureHandles',featureHandles, 'featureNames',featureNames, 'saveROIs',saveROIs, 'ROIcolormap',ROIcolormap, 'edges', edges, 'verbose',sign(verbose)*(verbose+1));
                    end;

                    % Export ROIs to excel sheet
                    xlsFilename = fullfile(projectPath,[projectName '_extractedFeaturesFromROIs.xls']);
                    xlsSheet = [mapType '.' maps{m}]; % Use maps{m} instead of map to names with underscore instead of space
                    if (verbose)
                        dispts('   Exporting extracted features from ROIs...', numDisplaySpaces);
                        dispts(['      File:  ' xlsFilename], numDisplaySpaces);
                        dispts(['      Sheet: ' xlsSheet], numDisplaySpaces);
                    end;
                    exportROIs2xls(xlsFilename, xlsSheet, ROIsExtracted);

                else
                    warning(['Specified map does not exist (Map type: ' mapType ', map: ' map '): ' mapPath]);
                end;
            end;
        end;
    else
        for i = 1:length(mapsStruct)
            mapType = mapsStruct(i).type;
            mapName = mapsStruct(i).shortName;
            mapPath = mapsStruct(i).fullPath;
            refMapPath = fullfile(refProjectPath, refProjectName, mapsStruct(i).relPath, [refProjectName mapsStruct(i).extName]);
            if (verbose)
                dispts(['Map (' num2str(i) '/' num2str(numMaps) '): ' mapType '.' mapName '...'], numDisplaySpaces);
            end;
            % If map exists, proceed to extract ROIs from it
            if (exist(mapPath,'file'))
                [~, xlsROIfilenameWoExtension, ~] = fileparts(ROIfile);
                if (exist(refMapPath,'file')) && (~isempty(refPix4dProject))
                    ROIsExtracted = extractROIsFromGeotiff(mapPath, ROIs, ROIheader, 'refMapFile',refMapPath, 'featureHandles',featureHandles, 'featureNames',featureNames, 'saveROIs',saveROIs, 'ROIcolormap',ROIcolormap, 'edges', edges, 'Verbose',sign(verbose)*(verbose+1));
                    xlsFilename = fullfile(projectPath,[projectName '__' xlsROIfilenameWoExtension '__extractedFeaturesFromROIs_REF.xls']);
                else
                    ROIsExtracted = extractROIsFromGeotiff(mapPath, ROIs, ROIheader, 'featureHandles',featureHandles, 'featureNames',featureNames, 'saveROIs',saveROIs, 'ROIcolormap',ROIcolormap, 'edges', edges, 'verbose',sign(verbose)*(verbose+1));
                    xlsFilename = fullfile(projectPath,[projectName '__' xlsROIfilenameWoExtension '__extractedFeaturesFromROIs.xls']);
                end;

                % Export ROIs to excel sheet
                
                xlsSheet = [mapType '.' mapName]; % Use maps{m} instead of map to names with underscore instead of space
                if (verbose)
                    dispts('   Exporting extracted features from ROIs...', numDisplaySpaces);
                    dispts(['      File:  ' xlsFilename], numDisplaySpaces);
                    dispts(['      Sheet: ' xlsSheet], numDisplaySpaces);
                end;
                exportROIs2xls(xlsFilename, xlsSheet, ROIsExtracted);

            else
                warning(['Specified map does not exist (Map type: ' mapType ', map: ' mapName '): ' mapPath]);
            end;
        end
    end
    
    if (verbose)
        dispts('Project completed!', numDisplaySpaces);
    end
end

function p = parseInputs(varargin)
    p = inputParser();
    addParameter(p,'mapsStruct',[], @(x)validateattributes(x, {'struct','char'},{'nonempty'}));
    addParameter(p,'saveROIs',false, @(x)validateattributes(x, {'logical','numeric'},{'nonempty'}));
    addParameter(p,'refPix4dProject','', @(x)validateattributes(x, {'string','char'},{'nonempty'}));
    addParameter(p,'ROIcolormap', parula(256));
    addParameter(p,'ROIfile','', @(x)validateattributes(x, {'string','char'},{'nonempty'}));
    addParameter(p,'ROIs',[], @(x)validateattributes(x, {'struct'},{'nonempty'}));
    addParameter(p,'featureHandles',{@(I,m)mean(I(m))}, @(x)validateattributes(x, {'function_handle','cell'},{'nonempty'}));
    addParameter(p,'featureNames',[],@(x)validateattributes(x, {'cell'},{'nonempty'}));
    addParameter(p,'verbose',0, @(x)validateattributes(x, {'logical','numeric'},{'nonempty'}));
    addParameter(p,'edges',0,@(x)validateattributes(x, {'numeric'},{'nonempty'}));
    
   parse(p, varargin{:}); 
end
