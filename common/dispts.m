function dispts( str, numSpaces )
%DISPTS Summary of this function goes here
%   Detailed explanation goes here

    if (nargin < 2)
        numSpaces = 0;
    end;
    
    spacing = repmat(' ',1,numSpaces);
    
    timestr = ['[' datestr(now,'YYYY/mm/dd HH:MM:SS') '] '];
    disp([timestr spacing str]);

end

