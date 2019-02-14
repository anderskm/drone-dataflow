function [ pUTM ] = camLine2PlanteIntersection(camLine, cameraPosition, cameraOrientation, flightHeight, planeNormal)
%CAMLINE2PLANTEINTERSECTION Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 4) % If flight height is not specified, it is assumed, that the Z-coordinate of the camera position is the height of the flight, and that the ground plane is located at 0.
        flightHeight = cameraPosition(3);
    end

    % Define origo of line to be camera position
    l0 = cameraPosition(:);
    
    % Define planar surface
    if (nargin < 5)
        % Plane not defined. Assume horizontal plane
        n = [0 0 1]'; % Normal vector
    else
        n = planeNormal(:); % Make sure it is a column vector
    end
    p0 = [cameraPosition(1) cameraPosition(2) cameraPosition(3)-flightHeight]'; % Origo position
    
    % Perform inverse yaw, pitch, roll rotation
    R = rotmatYPR(cameraOrientation(1), cameraOrientation(2), cameraOrientation(3));
    R = R(1:3,1:3);
    lr = R\camLine'; % Inverse yaw, pitch, roll rotation
    
    % Find intersection with plane
    pUTM = linePlaneIntersection( n, p0, l0, lr );

end

