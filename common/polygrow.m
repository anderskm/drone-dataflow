function [ X,Y ] = polygrow( X, Y, d)
%POLYGROW Grow polygon with respect to center of mass
%   Grow polygon by moving each point d away from its center of mass.


    % Center of mass
    X0 = mean(X);
    Y0 = mean(Y);
    
    Xm = X-X0;
    Ym = Y-Y0;
    
    r2 = Xm.^2 + Ym.^2;
    theta = atan2(Ym,Xm);
    
    rd = sqrt(r2 + d.^2);
    
    X = rd.*cos(theta) + X0;
    Y = rd.*sin(theta) + Y0;

end

