
camera.name = 'eBee_MultiSPEC_4C';
lensType = 'fisheye';

camera.requiredExifTags.Make = 'Airinov';
camera.requiredExifTags.Model = 'multiSPEC 4C';
camera.requiredExifTags.ImageWidth = '1280';
camera.requiredExifTags.ImageHeight = '960';

if (strcmp(lensType,'fisheye'))

    camera.image.size = [1280 960]; % px, [width, height]
    camera.image.principlePoint = [640 480]; % px, [width, height]

    camera.sensor.size = [4.8 3.6]; % mm, [width, height]
    camera.sensor.pixelSize = 3.75*10^-3; % mm
    camera.sensor.principlePoint = [2.4 1.8]; % mm, [width, height]

    camera.lens.type = 'fisheye'; % 'fisheye' or 'perspective'
    camera.lens.polynomial = [0 1 0.028743 -0.382359 0];
    camera.lens.transAffine = [1560   0;
                                 0  1560];

elseif (strcmp(lensType,'perspective'))

    camera.image.size = [5472; 3648]; % px, [width; height]
    camera.image.principlePoint = [2725; 1812]; % px, [width; height]

    camera.sensor.size = [13.1328; 8.7552]; % mm, [width; height]
    camera.sensor.pixelSize = 2.4*10^-3; % mm
    camera.sensor.principlePoint = [6.54; 4.34801]; % mm, [width; height]

    camera.lens.type = 'perspective'; % 'fisheye' or 'perspective'
    camera.lens.radial = [0.033, -0.209, 0.315];
    camera.lens.tangential = [0, 0];
    camera.lens.focalLengthPx = 4430.42;
    camera.lens.focalLengthMm = 10.633;
end

%% Extra

if (strcmp(camera.lens.type,'fisheye'))
    C = camera.image.principlePoint(:);
    M = camera.lens.transAffine;
    f = 2*M(1,1)/pi;
    
    p = camera.lens.polynomial;
    theta = @(x) 2/pi * atan(sqrt(sum(x.^2,2))./f);
    rho = @(x) p(1) + theta(x)*p(2) + theta(x).^2*p(3) + theta(x).^3*p(4) + theta(x).^4*p(5);
    optimParams = optimset('Display','off','Algorithm','levenberg-marquardt');
    
    camera.lens.focalLengthPx = f;
    camera.lens.focalLengthMm = mean(f./camera.image.size.*camera.sensor.size);
    camera.lens.thetaFunc = theta;
    camera.lens.rhoFunc = rho;
    camera.lens.optimParams = optimParams;
elseif (strcmp(camera.lens.type,'perspective'))
    
    r2 = @(x) (x(1).^2 + x(2).^2);
    radDist = @(x) (1 + camera.lens.radial(1)*r2(x) + camera.lens.radial(2)*r2(x).^2 + camera.lens.radial(3)*r2(x).^3);
    tanDistX = @(x) (2*camera.lens.tangential(1)*x(1).*x(2)) + (camera.lens.tangential(2)*(r2(x) + 2*x(1).^2));
    tanDistY = @(x) (2*camera.lens.tangential(2)*x(1).*x(2)) + (camera.lens.tangential(1)*(r2(x) + 2*x(2).^2));
    
    optimParams = optimset('Display','off','Algorithm','levenberg-marquardt');
    camera.lens.r2 = r2;
    camera.lens.radDist = radDist;
    camera.lens.tanDistX = tanDistX;
    camera.lens.tanDistY = tanDistY;
    camera.lens.optimParams = optimParams;
end

%%

[ l_ul ] = camPoint2Line( 1, 1, camera );
[ l_ur ] = camPoint2Line( camera.image.size(1), 1, camera );
[ l_lr ] = camPoint2Line( camera.image.size(1), camera.image.size(2), camera );
[ l_ll ] = camPoint2Line( 1, camera.image.size(2), camera );

camera.image.cornerLines.l_ul = l_ul;
camera.image.cornerLines.l_ur = l_ur;
camera.image.cornerLines.l_lr = l_lr;
camera.image.cornerLines.l_ll = l_ll;

save([camera.name '.mat'], 'camera');