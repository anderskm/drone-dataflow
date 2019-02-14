function [ mapsStruct ] = pix4dProject2mapsStruct( p4dprojectfilepath, mapTypes, oldType)
%PROJECT2MAPS Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 2)
        mapTypes = {'dsm','mosaic','reflectance','indices'};
    end;
    if (nargin < 3)
        oldType = false;
    end
    
    if (ischar(mapTypes))
        mapTypes = {mapTypes};
    end;
    
    if (exist(p4dprojectfilepath,'file'))
        [projectPath, projectName, ~] = fileparts(p4dprojectfilepath);

        if (oldType)
            [ mapsStruct ] = pix4dProject2mapsStruct_old( projectPath, projectName, mapTypes);
        else
            [ mapsStruct ] = pix4dProject2mapsStruct_new( projectPath, projectName, mapTypes);
        end
    else
        error('Specified Pix4D project file does not exist!');
    end;
    
    
    if (isempty(fieldnames(mapsStruct)))
        error('Could not detect any maps (DSM, orthophoto, reflectance or index).');
    end

end

function [ mapsStruct ] = pix4dProject2mapsStruct_new( projectPath, projectName, mapTypes)
  
    mapsStruct = struct();

    % Check for DSM and orthophoto
    if (exist(fullfile(projectPath, projectName,'3_dsm_ortho'),'dir'))

        % Check for DSM
        if (exist(fullfile(projectPath, projectName,'3_dsm_ortho','1_dsm'),'dir')) && any(ismember(mapTypes, 'dsm'))
            DSMs = dir(fullfile(projectPath, projectName,'3_dsm_ortho','1_dsm',[projectName '_dsm.tif']));
            if (~isempty(DSMs))
                for i = 1:length(DSMs)
                    [~, name, ~] = fileparts(DSMs(i).name);
                    type = 'dsm';
                    shortName = name(length(projectName) + 2:end);
                    fullName = DSMs(i).name;
                    extName = fullName(length(projectName)+1:end);
                    fullPath = fullfile(projectPath, projectName,'3_dsm_ortho','1_dsm', fullName);
                    relPath = fullfile('3_dsm_ortho','1_dsm');
                    [mapsStruct] = append2mapStruct(mapsStruct, type, shortName, extName, fullName, relPath, fullPath);
                end;
            end;
        end;

        % Check for orthophoto
        if (exist(fullfile(projectPath, projectName,'3_dsm_ortho','2_mosaic'),'dir')) && any(ismember(mapTypes, 'mosaic'))
            mosaics = dir(fullfile(projectPath, projectName,'3_dsm_ortho','2_mosaic',[projectName '_mosaic_*.tif']));
            if (~isempty(mosaics))
                for i = 1:length(mosaics)
                    [~, name, ~] = fileparts(mosaics(i).name);
                    type = 'mosaic';
                    shortName = name(length(projectName) + 9:end);
                    fullName = mosaics(i).name;
                    extName = fullName(length(projectName)+1:end);
%                     fullPath = fullfile(projectPath, projectName, '3_dsm_ortho','1_dsm', fullName);
%                     relPath = fullfile('3_dsm_ortho','1_dsm');
                    fullPath = fullfile(projectPath, projectName, '3_dsm_ortho', '2_mosaic', fullName);
                    relPath = fullfile('3_dsm_ortho', '2_mosaic');
                    [mapsStruct] = append2mapStruct(mapsStruct, type, shortName, extName, fullName, relPath, fullPath);
                end;
            end;
            mosaicsTransparent = dir(fullfile(projectPath, projectName,'3_dsm_ortho','2_mosaic',[projectName '_transparent_mosaic_*.tif']));
            if (~isempty(mosaicsTransparent))
                for i = 1:length(mosaicsTransparent)
                    [~, name, ~] = fileparts(mosaicsTransparent(i).name);
                    type = 'mosaic';
                    shortName = [name(length(projectName) + 21:end) 'Transparent'];
                    fullName = mosaicsTransparent(i).name;
                    extName = fullName(length(projectName)+1:end);
                    fullPath = fullfile(projectPath, projectName, '3_dsm_ortho', '2_mosaic', fullName);
                    relPath = fullfile('3_dsm_ortho', '2_mosaic');
                    [mapsStruct] = append2mapStruct(mapsStruct, type, shortName, extName, fullName, relPath, fullPath);
                end;
            end;
        end;
    end;
    % Check for indices and reflectance
    if (exist(fullfile(projectPath, projectName,'4_index'),'dir'))

        % Check for reflectances
%         if (exist(fullfile(projectPath, projectName,'4_index','reflectance'),'dir')) && any(ismember(mapTypes, 'reflectance'))
%             warning('Support for reflectance maps have not yet been implemented!');
%         end;        
        if (exist(fullfile(projectPath, projectName,'4_index','reflectance'),'dir')) && any(ismember(mapTypes, 'reflectance'))
            reflectanceMaps = dir(fullfile(projectPath, projectName,'4_index','reflectance',[projectName '_reflectance_*.tif']));
            if (~isempty(reflectanceMaps))
                for i = 1:length(reflectanceMaps)
                    [~, name, ~] = fileparts(reflectanceMaps(i).name);
                    type = 'reflectance';
                    shortName = name(length(projectName) + 14:end);
                    fullName = reflectanceMaps(i).name;
                    extName = fullName(length(projectName)+1:end);
                    fullPath = fullfile(projectPath, projectName, '4_index','reflectance', fullName);
                    relPath = fullfile('4_index','reflectance');
                    [mapsStruct] = append2mapStruct(mapsStruct, type, shortName, extName, fullName, relPath, fullPath);
                end;
            end;
            reflectanceMapsTransparent = dir(fullfile(projectPath, projectName,'4_index','reflectance',[projectName '_transparent_reflectance_*.tif']));
            if (~isempty(reflectanceMapsTransparent))
                for i = 1:length(reflectanceMapsTransparent)
                    [~, name, ~] = fileparts(reflectanceMapsTransparent(i).name);
                    type = 'reflectance';
                    shortName = [name(length(projectName) + 26:end) 'Transparent'];
                    fullName = reflectanceMapsTransparent(i).name;
                    extName = fullName(length(projectName)+1:end);
                    fullPath = fullfile(projectPath, projectName, '4_index', 'reflectance', fullName);
                    relPath = fullfile('4_index', 'reflectance');
                    [mapsStruct] = append2mapStruct(mapsStruct, type, shortName, extName, fullName, relPath, fullPath);
                end;
            end;
        end;

        % Check for indices
        if (exist(fullfile(projectPath, projectName,'4_index','indices'),'dir')) && any(ismember(mapTypes, 'indices'))
            indices = dir(fullfile(projectPath, projectName,'4_index','indices'));

            % Check if any indices were found
            if (~isempty(indices))
                % Loop through all found indices. If an index exist,
                % add it to the struct
                for i = 1:length(indices)
                    [~, indexName, ~] = fileparts(indices(i).name);
                    if (exist(fullfile(projectPath, projectName,'4_index','indices', indexName,[projectName '_index_' indexName '.tif']),'file'))
                        type = 'indices';
                        shortName = indexName;
                        fullName = [projectName '_index_' indexName '.tif'];
                        extName = fullName(length(projectName)+1:end);
                        fullPath = fullfile(projectPath, projectName, '4_index', 'indices', indexName, fullName);
                        relPath = fullfile('4_index', 'indices', indexName);
                        [mapsStruct] = append2mapStruct(mapsStruct, type, shortName, extName, fullName, relPath, fullPath);
                    end;
                end;
            end;
        end;
    end;
    
end

function [mapsStruct] = append2mapStruct(mapsStruct, type, shortName, extName, fullName, relPath, fullPath)
    if (isempty(fieldnames(mapsStruct)))
        mapsStruct.type = type;
        mapsStruct.shortName = shortName;
        mapsStruct.extName = extName;
        mapsStruct.fullName = fullName;
        mapsStruct.relPath = relPath;
        mapsStruct.fullPath = fullPath;
    else
        mapsStruct(end+1).type = type;
        mapsStruct(end).shortName = shortName;
        mapsStruct(end).extName = extName;
        mapsStruct(end).fullName = fullName;
        mapsStruct(end).relPath = relPath;
        mapsStruct(end).fullPath = fullPath;
    end
end

function [ mapsStruct ] = pix4dProject2mapsStruct_old( projectPath, projectName, mapTypes)

    mapsStruct = struct();

    % Check for DSM and orthophoto
    if (exist(fullfile(projectPath, projectName,'3_dsm_ortho'),'dir'))

        % Check for DSM
        if (exist(fullfile(projectPath, projectName,'3_dsm_ortho','1_dsm'),'dir')) && any(ismember(mapTypes, 'dsm'))
            DSMs = dir(fullfile(projectPath, projectName,'3_dsm_ortho','1_dsm',[projectName '_dsm.tif']));
            if (~isempty(DSMs))
                for i = 1:length(DSMs)
                    [~, name, ~] = fileparts(DSMs(i).name);
                    dsmName = name(length(projectName) + 2:end);
                    mapsStruct.dsm.(strrep(dsmName,' ','_')) = dsmName;
                end;
            end;
        end;

        % Check for orthophoto
        if (exist(fullfile(projectPath, projectName,'3_dsm_ortho','2_mosaic'),'dir')) && any(ismember(mapTypes, 'mosaic'))
            mosaics = dir(fullfile(projectPath, projectName,'3_dsm_ortho','2_mosaic',[projectName '_mosaic_*.tif']));
            if (~isempty(mosaics))
                for i = 1:length(mosaics)
                    [~, name, ~] = fileparts(mosaics(i).name);
                    mosaicName = name(length(projectName) + 9:end);
                    mapsStruct.mosaic.(strrep(mosaicName,' ','_')) = mosaicName;
                end;
            end;
            mosaicsTransparent = dir(fullfile(projectPath, projectName,'3_dsm_ortho','2_mosaic',[projectName '_transparent_mosaic_*.tif']));
            if (~isempty(mosaicsTransparent))
                for i = 1:length(mosaicsTransparent)
                    [~, name, ~] = fileparts(mosaicsTransparent(i).name);
                    mosaicName = name(length(projectName) + 21:end);
                    mosaicName = [mosaicName 'Transparent'];
                    mapsStruct.mosaic.(strrep(mosaicName,' ','_')) = mosaicName;
                end;
            end;
        end;
    end;
    % Check for indices and reflectance
    if (exist(fullfile(projectPath, projectName,'4_index'),'dir'))

        % Check for reflectances
        if (exist(fullfile(projectPath, projectName,'4_index','indices'),'dir')) && any(ismember(mapTypes, 'reflectance'))
            warning('Support for reflectance maps have not yet been implemented!');
        end;

        % Check for indices
        if (exist(fullfile(projectPath, projectName,'4_index','indices'),'dir')) && any(ismember(mapTypes, 'indices'))
            indices = dir(fullfile(projectPath, projectName,'4_index','indices'));

            % Check if any indices were found
            if (~isempty(indices))
                % Loop through all found indices. If an index exist,
                % add it to the struct
                for i = 1:length(indices)
                    [~, indexName, ~] = fileparts(indices(i).name);
                    if (exist(fullfile(projectPath, projectName,'4_index','indices', indexName,[projectName '_index_' indexName '.tif']),'file'))
                        mapsStruct.indices.(indexName) = indexName;
                    end;
                end;
            end;
        end;
    end;
end