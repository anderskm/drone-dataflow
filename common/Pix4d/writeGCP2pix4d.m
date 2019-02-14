function writeGCP2pix4d(outputFile, id, E, N, alt)
%WRITEGCP2PIX4D Summary of this function goes here
%   Detailed explanation goes here

fid = fopen(outputFile,'w');
for i = 1:length(E)
%     fwrite(fid,GCPmat(i,:));
    fprintf(fid, 'GCP_%s,%2.16f,%3.16f,%3.16f\r\n',id{i},E(i),N(i),alt(i));
%     [N, E, Zone, lcm] = ell2utm(lat(i)',lon(i)')
%     fprintf(fid,'GCP%03.0f,%f,%f\r\n',i,E,N)
%     plot(E,N,'.')
%     hold on;
%     text(E,N,['GCP' num2str(i)])
end;
fclose(fid);

end

