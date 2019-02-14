function [ l ] = camPoint2Line( x, y, camera )
%CAMPOINT2LINE Summary of this function goes here
%   Detailed explanation goes here


    if (strcmp(camera.lens.type, 'fisheye'))
        l = fisheyePoint2Line([x; y], camera);
    elseif (strcmp(camera.lens.type, 'perspective'))
        l = perspectivePoint2Line([x; y], camera);
    else
        error('Unknown lens type.');
    end

end

function l = fisheyePoint2Line(pointPX, camera)

    % Setup
%     Xd = pointPX;
%     C = camera.image.principlePoint(:);
%     M = camera.lens.transAffine;
    
    % Inverse affine transformation
    Xh = mldivide(camera.lens.transAffine, pointPX - camera.image.principlePoint(:));

    % Focal length (in px or mm?)
%     f = 2*M(1,1)/pi;

    
%     p = camera.lens.polynomial;
%     theta = @(x) 2/pi * atan(sqrt(sum(x.^2,2))./f);
%     rho = @(x) p(1) + theta(x)*p(2) + theta(x).^2*p(3) + theta(x).^3*p(4) + theta(x).^4*p(5);
    rho = camera.lens.rhoFunc;
    func = @(x) (Xh(1) - rho(x).*x(:,1)./sqrt(sum(x.^2,2))).^2 + (Xh(2) - rho(x).*x(:,2)./sqrt(sum(x.^2,2))).^2;

    % Solve for X' and Y' under constraint that Z' = focal length
    x = lsqnonlin(func, Xh',[-Inf -Inf],[Inf Inf],camera.lens.optimParams);

    l = [x, camera.lens.focalLengthPx];

end

function l = perspectivePoint2Line(pointPX, camera)

    % Pixel coordinates to distorted homogeneous coordinates
    Xhd = (camera.image.principlePoint(:)-pointPX)./camera.lens.focalLengthPx;
    
    % Setup function handles to solve for line direction
    func = @(x) (Xhd(1) - (camera.lens.radDist(x).*x(1) + camera.lens.tanDistX(x))).^2 + (Xhd(2) - camera.lens.tanDistY(x)).^2;
    
    x = lsqnonlin(func, Xhd',[-Inf -Inf],[Inf Inf],camera.lens.optimParams);

    l = [x, 1];
end