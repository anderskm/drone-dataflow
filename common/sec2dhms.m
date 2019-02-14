function [ output, H, M, S ] = sec2dhms( s )
%SEC2DHMS Seconds to days, hours, minutes and seconds
    
    

    D = floor(s/86400);
    s = s - D*86400;
    H = floor(s/3600);
    s = s - H*3600;
    M = floor(s/60);
    S = s - M*60;
%     nargout
    if (nargout < 1)
        disp([num2str(D) ' days, ' num2str(H) ' hours, ' num2str(M) ' minutes, ' num2str(S) ' seconds']);
    elseif (nargout == 1)
        output = [num2str(D) ' days, ' num2str(H) ' hours, ' num2str(M) ' minutes, ' num2str(S) ' seconds'];
    else
        output = D;
    end;


end

