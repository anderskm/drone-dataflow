function [ yaw, theta ] = estimateYaw( N, E )
%ESTIMATEYAW Estimate yaw from a set of UTM coordinates
%
% USAGE
%   [yaw] = estimateYaw(N, E)
%   [yaw, theta] = estimateYaw(N, E)
%
% INPUTS:
%   N    - vector of UTM northings (m).
%   E    - vector of UTM eastings (m).
%
% OUTPUTS:
%  yaw   - Vector of estimated yaw of each point (N,E) (degrees)
%  theta - Vector of estimated angle of each point (counter-clockwise
%          rotation, East = 0 degrees)
%
% Note: The estimated yaw is within +/- 10-15 degrees of the true yaw.
%       Tested on images from the Multispec 4C on the eBee. These images
%       have yaw, pitch and roll encoded within their metadata.
%       From the same test:
%       Mean absolute error     = 6.1 degrees
%       Root mean squared error = 7.6 degrees

    % Estimate the angle from point to point
    theta = atan2(N(2:end)-N(1:end-1),E(2:end)-E(1:end-1)).*180/pi;
    theta = [theta(:); theta(end)];
%     theta = mod(theta, 360);

    % Handle end of corridor cases
    thetaDiff1 = [theta(2:end)-theta(1:end-1); 0];
    thetaDiff2 = [mod(theta(2:end),360)-mod(theta(1:end-1),360); 0];
    thetaDiff = min(abs(thetaDiff1), abs(thetaDiff2));
%     thetaDiff = [theta(2:end)-theta(1:end-1); 0]; % Find the difference betweeen subsequent points
    idx = abs(thetaDiff) > 45; % Find index of points, where the difference is more than 45 degrees
    theta(find(idx)) = theta(max(find(idx)-1,1)); % Set the angle of said points equal to the previous point

    % Convert for normal angles to yaw
    % "Normal angles":  X/east = 0, positive rotation is counter-clockwise
    % Yaw:              Y/north = 0, positive rotation is clockwise
    yaw = -theta + 90;

end
