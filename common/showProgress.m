function newString = showProgress( oldString, newString, timeStamp )
%SHOWPROGRESS Summary of this function goes here
%   Detailed explanation goes here

    delOldString = '';
    if (~strcmp(oldString,''))
        delOldString = repmat('\b',1,length(oldString)+1);
    end;
    
    fprintf([delOldString newString '\n']);

end