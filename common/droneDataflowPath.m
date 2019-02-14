function [ path ] = droneDataflowPath( )
%GETDRONEDATAFLOWPATH Summary of this function goes here
%   Detailed explanation goes here

    path = mfilename('fullpath');
    % Split path at / and \
%     pathParts = strsplit(path,{'\','/'});
%     path = fullfile(pathParts{1:end-3});

    % Remove droneDataflowPath, common and MATLAB
    for i = 1:3
        [path, ~, ~] = fileparts(path);
    end;

end
