function [ messageStruct ] = parseBBXmessage( rawMessage, header )
%PARSEBBXMESSAGE Summary of this function goes here
%   Detailed explanation goes here

    msgId = getMessageId(rawMessage);
    headerId = header.id;
    
    if (msgId ~= headerId)
        error(['Message id (' num2str(msgId) ') and header id (' num2str(headerId) ') does not match!']);
    end
    
    messageStruct = struct([]);
    fieldStartIdx = [0 cumsum([header.fields.size])];
    for f = 1:length(header.fields)
        word = rawMessage(12 + fieldStartIdx(f) + (1:header.fields(f).size));
        messageStruct(1).(header.fields(f).name) =  parseWord(word, header.fields(f).type);
    end;

end

function id = getMessageId(rawMessage)
    id = double(rawMessage(5:6));
    id = id(1) + id(2)*256;
end

function value = parseWord(word, type)
 % DOES NOT ACCOUNT FOR SIZES LARGER THAN 1!!!!

    if (type == 1)
        value = double(word);
    elseif (type == 3)
        value = 0;
        word = double(word);
        for i = 1:length(word)
            value = value + word(i) * 2^((i-1)*8);
        end
    elseif (type == 5)
        value = typecast(uint8(word),'uint32');
    elseif (type == 6)
        value = (typecast(uint8([word]),'uint64'));
    elseif (type == 8)
        value = typecast(uint8(word),'single');
    elseif (type == 9)
        value = (typecast(uint8([word]),'double'));
    else
        value = {word};
    end
end