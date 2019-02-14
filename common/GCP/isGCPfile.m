function [tf, TFout, sheetsOut] = isGCPfile(xlsFullfile)
%ISROIFILE Summary of this function goes here
%   Detailed explanation goes here
%
% NOTE: Can be slow!

    [~, sheets, ~] = xlsfinfo(xlsFullfile);
    TF = zeros(size(sheets),'logical');
    for i = 1:length(sheets)
        try
            [ GCPs, header ] = readGCPfromXLS( xlsFullfile, sheets{i} );
            TF(i) = true;
        catch ME
            TF(i) = false;
        end
    end
    
    tf = any(TF);
    if (nargout > 1)
        TFout = TF;
    end
    if(nargout > 2)
        sheetsOut = sheets;
    end

end
