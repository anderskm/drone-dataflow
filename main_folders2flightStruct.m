clearvars;
close all;

% folder = 'C:\Pix4d\Suiyan';
% folder = 'C:\Pix4d\Drone-dataflow\Process';

% Locates images, pix4d projects, ROI files and GCP files
%%
addpath(genpath('common'));

%%
if (~exist('folder','var'))
    folder = uigetdir(pwd,'Select folder');
    if (folder == 0)
        error('Folder selection cancelled by user.');
    end
end

%%

content = dir(folder);
content(1:2) = []; % Remove . and ..

%%
flightStructs = struct([]);
for c = 1:length(content)
    if (content(c).isdir)
        if (exist('flightStruct','var'))
            clear flightStruct;
        end
        
        flightFolderPath = fullfile(folder,content(c).name);
        
        %% Locate GCPs
        GCPs = dir(fullfile(flightFolderPath,'GCP','*.xlsx'));
        GCPfile = '';
        for g = 1:length(GCPs)
            GCPfile = fullfile('GCP',GCPs(g).name);
            if (isGCPfile(fullfile(flightFolderPath,GCPfile)))
                break;
            end
        end
        
        %% Locate ROIs
        ROIs = dir(fullfile(flightFolderPath,'ROI','*.xlsx'));
        ROIfiles = cell(1,0);
        for g = 1:length(ROIs)
            ROIfile = fullfile('ROI',ROIs(g).name);
            if (isROIfile(fullfile(flightFolderPath,ROIfile)))
                ROIfiles{end+1} = ROIfile;
            end
        end

        %% Locate pix4d project(s)
        % Locate pix4d project folders
        p4dProjectFolders = dir(fullfile(flightFolderPath,'Processed data'));
        p4dProjectFolders(1:2) = [];
        for f = 1:length(p4dProjectFolders)
            if (p4dProjectFolders(f).isdir)
                p4dProjectFolder = fullfile('Processed data',p4dProjectFolders(f).name);
                % Locate pix4d project files
                p4dProjectFiles = dir(fullfile(flightFolderPath,p4dProjectFolder,'*.p4d'));
                
                for p = 1:length(p4dProjectFiles)
                    p4dProjectFilename = p4dProjectFiles(p).name;
                    if (strcmp(p4dProjectFilename(end-7:end),'_rgb.p4d'))
                        % Skip projects based on the RGB images from Sequoia
                    elseif (contains(p4dProjectFilename,'_backup_'))
                        % Skip backup p4d projects
                    else
                        % Process
                        
                        % Locate images
                        if (exist(fullfile(flightFolderPath,p4dProjectFolder,'img'),'dir'))
                            subfolders = dir(fullfile(flightFolderPath,p4dProjectFolder,'img'));
                            subfolders(1:2) = []; % Remove . and ..
                            subfolders = subfolders([subfolders.isdir]);
                            
                            if (isempty(subfolders))
                                imageFolder = fullfile(p4dProjectFolder,'img');
                            else
                                imageFolder = fullfile(p4dProjectFolder,'img',subfolders(1).name); % (1) --> Magically select 'msp' over 'rgb'
                            end
                            
                            [images, imageFolderFull, ~] = listImages(fullfile(flightFolderPath,imageFolder));
                            [cameraModel] = detectCameraModel(imageFolderFull, images(1).name);
                            
                            flightStruct.path = flightFolderPath;
                            flightStruct.GCPfile = GCPfile;
                            flightStruct.ROIfiles = ROIfiles;
                            flightStruct.p4dProject = fullfile(p4dProjectFolder,p4dProjectFilename);
                            flightStruct.imageFolder = imageFolder;
                            flightStruct.cameraModel = cameraModel;
                            
                        end
                    end
                end
            end
        end
        if (exist('flightStruct','var'))
            if (isempty(flightStructs))
                flightStructs = flightStruct;
            else
                flightStructs(end+1) = flightStruct;
            end
        else
            warning('Could not create flightstruct for flight. Please check, that p4d project and corresponding img folder exist.')
            warning(flightFolderPath)
        end
    end
end

%%

for i = 1:length(flightStructs); disp(flightStructs(i)); end

% save(fullfile(folder,'flightStruct.mat'),'flightStructs')