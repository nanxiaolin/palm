function palm_scf_to_ctcsv( scf, outfile)
%
% function palm_scf_to_ctcsv ( scf, outfile )
%
% function that converts sorted coordinates into csv for SR_Tesseler
% 
% SR_Tesseler CSV format:
%
%% Line 1: header; Lines 2+: [x, y, intensity, frame]
%% Header format: x[pix], y[pix], intensity, frame

	num_rows = length(scf(:, 1));

	header = ['x[pix],y[pix],intensity,frame'];	
	[path, name, ext] = fileparts(outfile);

	fprintf("Exporting data to %s........ ", [name ext]);
	
	fp = fopen(outfile,'w');
	fprintf(fp,'%s',header);
	
	for i = 1 : num_rows
		fprintf(fp,'\n%.2f,%.2f,%.1f,%d', scf(i,1),scf(i, 2), scf(i, 3), scf(i, 4));
		
		if (mod(i, 10000) == 0) || (i == num_rows)
			fprintf('\b\b\b\b\b\b%5.1f%%', i*100/num_rows);
		end
	end
	fclose(fp);
	fprintf('\b\b\b\b\b\b... Done. File saved in the input file folder.\n'); 