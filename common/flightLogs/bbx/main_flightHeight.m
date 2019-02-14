clearvars;
close all;

%% Do not change below this line
%% eBee log-file location

% Ask user to select eBee log-file
[logFileName,logFilePath,FilterIndex] = uigetfile('*.bbx','Select a eBee log-file (*.bbx)');
if all(logFileName == 0) || all(logFilePath == 0)
    error('Folder selection cancelled by user.');
end
logFile = fullfile(logFilePath, logFileName);


%% Read full log-file into memory
tic;
disp('Reading all data from log file into memory...');
fid = fopen(logFile,'r');
A = fread(fid,Inf,'uint8');
fclose(fid);
disp([num2str(length(A)) ' bytes read into memory.']);
toc

%% Read headers

disp('Reading headers...');
tic;
% Set magic numbers
byteIndexOfNumberOfHeaders = 13;
firstHeaderStartIdx = 15;

numHeaders = A(byteIndexOfNumberOfHeaders);
headerStartIdx = firstHeaderStartIdx;
headers = struct();
for h = 1:numHeaders
    headerId = A(headerStartIdx);
    headerFieldType = A(headerStartIdx+1);
    headerNameLength = A(headerStartIdx+2);
    headerName = char(A(headerStartIdx+2+(1:headerNameLength))');
    headerNumFields = A(headerStartIdx+3+headerNameLength);
    
    fieldStartIdx = headerStartIdx + 2 + headerNameLength + 2;
    fields = struct([]);
    for f = 1:headerNumFields
        fieldType = A(fieldStartIdx + 1);
        fieldNameLength = A(fieldStartIdx + 2);
        fieldName = char(A(fieldStartIdx + 2 + (1:fieldNameLength))');
        fieldWords = A(fieldStartIdx + 2 + fieldNameLength + (1:2));
        fieldWords = fieldWords(1) + 256*fieldWords(2);
        fieldSize = NaN;
        if (fieldType == 0)
            fieldSize = 1*fieldWords;
        elseif (fieldType == 1)
            fieldSize = 1*fieldWords;
        elseif (fieldType == 2)
            fieldSize = 2*fieldWords;
        elseif (fieldType == 3)
            fieldSize = 2*fieldWords;
        elseif (fieldType == 4)
            fieldSize = 4*fieldWords;
        elseif (fieldType == 5)
            fieldSize = 4*fieldWords;
        elseif (fieldType == 6)
            fieldSize = 8*fieldWords;
        elseif (fieldType == 7)
            fieldSize = 8*fieldWords;
        elseif (fieldType == 8)
            fieldSize = 4*fieldWords;
        elseif (fieldType == 9)
            fieldSize = 8*fieldWords;
        end
        
        fields(f).name = fieldName;
        fields(f).type = fieldType;
        fields(f).nameLength = fieldNameLength;
        fields(f).words = fieldWords;
        fields(f).size = fieldSize;
        fields(f).fieldStartIdx = fieldStartIdx;
        
        fieldStartIdx = fieldStartIdx + 2 + fieldNameLength + 2;
    end
    
    headers(h).startIdx = headerStartIdx;
    headers(h).name = headerName;
    headers(h).id = headerId;
    headers(h).type = headerFieldType;
    headers(h).nameLength = headerNameLength;
    headers(h).numFields = headerNumFields;
    headers(h).fields = fields;
    headers(h).messageSize = sum([fields.size]);
    
    headerStartIdx = fieldStartIdx+1;
end
toc
%%

disp('Reading messages...');
tic;
firstMessageIdx = headerStartIdx + 2;
messageIdx = firstMessageIdx;
messages = struct();
numMessages = 0;
while(messageIdx < length(A)-14)
    numMessages = numMessages+1;
    if (numMessages == 13)
        disp(' ');
    end
    messageBegin = A(messageIdx + (0:3));
    messageType = A(messageIdx + 4);
    messageMetadata = A(messageIdx + (0:11));
    messageSizeExpected = headers(messageType+1).messageSize;
    messageEnd = messageIdx+12 + messageSizeExpected + (0:1);
    if (max(messageEnd) > length(A))
        warning('Terminating message reading early as expected message length is outside data range.');
        break;
    end
    messageSizeRead = A(messageIdx+12 + messageSizeExpected + (0:1));
    messageSizeRead = messageSizeRead(1) + 256*messageSizeRead(2);
    
    if (messageSizeExpected ~= messageSizeRead)
        error('Expected message size and specified size of message in message did not match.');
    end
    message = A(messageIdx + (0:(12 + messageSizeExpected+1)))';
    
    messages(numMessages).type = messageType;
    messages(numMessages).size = messageSizeRead;
    messages(numMessages).metadata = messageMetadata;
    messages(numMessages).idx = messageIdx;
    messages(numMessages).message = message;
    
    messageIdx = messageIdx+12 + messageSizeExpected + 2;
end
disp([num2str(length(messages)) ' messages read from log file!']);
toc
%%

% headerName = 'cam_PhotoTag_bb';
% 
% headerName = 'gpsglue_bbGPSData';
% headerName = 'gpsglue_bbTimeUTC';
% headerName = 'gps_identification';
% headerName = 'hd_bb';
headerName = 'sth_State_bb';

disp(['Locating all ' headerName ' messages...']);
tic;

% Locate cam_PhotoTag header
headerIdx = find(ismember({headers.name},headerName));
if (isempty(headerIdx))
    error(['Could not locate header: ' headerName]);
end;
header = headers(headerIdx);

% Find all messages related to capturing images
camMessagesIdx = find([messages.type] == header.id);
disp([num2str(length(camMessagesIdx)) ' ' headerName ' messages located.'])
toc
%%

disp(['Parsing all ' headerName ' messages...'])

lat = zeros(1,length(camMessagesIdx));
lon = zeros(1,length(camMessagesIdx));
time = zeros(1,length(camMessagesIdx));
speedEast = zeros(1,length(camMessagesIdx));
speedNorth = zeros(1,length(camMessagesIdx));
speedUp = zeros(1,length(camMessagesIdx));
speedAir = zeros(1,length(camMessagesIdx));
speed = zeros(1,length(camMessagesIdx));
altitude = zeros(1,length(camMessagesIdx));
for i = 1:length(camMessagesIdx)
    camMessage = messages(camMessagesIdx(i));
    msgStruct = parseBBXmessage(camMessage.message, header);
    lat(i) = msgStruct.latitude;
    lon(i) = msgStruct.longitude;
%     lat(i) = msgStruct.lat;
%     lon(i) = msgStruct.lon;
%     time(i) = datenum(msgStruct.utcYear, msgStruct.utcMonth, msgStruct.utcDay, msgStruct.utcHour, msgStruct.utcMin, double(msgStruct.utcSec));
    time(i) = msgStruct.time;
%     speedEast(i) = msgStruct.eastSpeed;
%     speedNorth(i) = msgStruct.northSpeed;
%     speedUp(i) = msgStruct.upSpeed;
%     speedAir(i) = msgStruct.airSpeed;
%     speed(i) = sqrt((msgStruct.eastSpeed).^2+(msgStruct.northSpeed).^2 + (msgStruct.upSpeed).^2);
    speed(i) = msgStruct.groundSpeed;
    altitude(i) = msgStruct.altitudeWgs84;
end;
disp([num2str(length(camMessagesIdx)) ' ' headerName ' messages parsed.'])

toc

%% Calculate and plot ground level, flight level and flight height

[ flightHeight, groundLevel, flightLevel ] = altitudesToFlightHeight( altitude );

figure;
plot(altitude);
hold on;
plot([1 length(altitude)],[groundLevel groundLevel]);
plot([1 length(altitude)],[flightLevel flightLevel]);
legend('Log',['Ground level, ' num2str(groundLevel,'%.1f') ' m'],['Flight level, ' num2str(flightLevel,'%.1f') ' m'],'Location','EastOutside');
xlabel('Log entry no.');
ylabel('Altitude, m');
title(['Flight altitude: ' num2str(flightHeight,'%.1f') ' m']);


%%

[ flightHeight, groundLevel, flightLevel ] = bbx2flightHeight( logFile );


