function [ X,Y,Z ] = caminvtran( x, y, camera, cameraPosition, cameraOrientation, flightHeight)
%CAMINVTRAN Camera inverse transformation
%   Calculates the inverse transformation of the camera. That is from image
%   coordinates to world coordinates. It assumes planar surface beneath the
%   camera.

    if (nargin < 6)
        flightHeight = cameraPosition(3);
    end;
    
    % Convert pixel coordinates to infinite line of potential points from
    % the camera
    [ l ] = camPoint2Line( x, y, camera );
    
    % Define origo of line to be camera position
    l0 = cameraPosition(:);
    
    % Define planar surface
    n = [0 0 1]'; % Normal vector
    p0 = [cameraPosition(1) cameraPosition(2) cameraPosition(3)-flightHeight]'; % Origo position
    
    % Perform inverse yaw, pitch, roll rotation
    R = rotmatYPR(cameraOrientation(1), cameraOrientation(2), cameraOrientation(3));
    R = R(1:3,1:3);
    lr = R\l'; % Inverse yaw, pitch, roll rotation
    
    % Find intersection with plane
    pUTM = linePlaneIntersection( n, p0, l0, lr );
    
    if (nargout == 3)
        X = pUTM(1);
        Y = pUTM(2);
        Z = pUTM(3);
    else
        X = pUTM;
    end
end
