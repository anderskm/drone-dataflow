function [ sheet, sheets] = xlsSelectSheet( xlsFullfile,  sheetSelection)
%XLSSELECTSHEET
% Select a sheet from a excel spread sheet

    [~, xlsROIfile, ext] = fileparts(xlsFullfile);

    [~, sheets, ~] = xlsfinfo(xlsFullfile);
    if (numel(sheets) == 1)
        disp('Only one sheet detected.');
        sheet = sheets{1};
    else
        if (nargin < 2)
            [sheetSelection,ok] = listdlg('ListString', sheets, ...
                                     'SelectionMode','single', ...
                                     'ListSize',[300 300], ...
                                     'Name','Select sheet', ...
                                     'PromptString',['Select a sheet from "' xlsROIfile ext '"'], ...
                                     'OKString','OK',...
                                     'CancelString','Cancel');
            if (strcmp(ok,'OK') || (ok == 1))
                sheet = sheets{sheetSelection};
            else
                error('Sheet selection cancelled by user!');
            end
        else
            sheet = sheets{sheetSelection};
        end
    end
    disp(['Sheet selected         : ' sheet])

end

