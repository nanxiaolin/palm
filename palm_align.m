function palm_align(object, event)
%
% function palm_align(object, event)
%
% This function responds to the 'align' button click and calls UI for image alignment within palm.
%
% 04/28/2022. Xiaolin Nan (OHSU)
% Initial version only deals with two images at a time. The outputs are one mcc file with the two scf channels
% along with their coordinates and fiducials.

	%%%%%% CODE BEGINS %%%%%%
	%
	% First, callout a file opening dialog to load the cor file for the fixed image.
	
	if nargin == 0
		object = 0;
	end
	
	extension = {'*.cor', 'Unsorted Coordinate File (*.COR)'};
	
    [filename, pathname_fix] = uigetfile(extension, 'Select the reference (fixed) image');

    if filename == 0
        return;
	end
        
    [path, name_fix, ext] = fileparts(filename);
    fixed_file = fullfile(pathname_fix, filename);
	
	% load the scf data from fixed_file
	scf_fix = struct2array(load(fixed_file, '-mat', 'scf'));
	if ~isempty(scf_fix)
		disp(sprintf('Reference (fixed) image %s successfully loaded.', filename));
	else
		disp(sprintf('Reference (fixed) image %s failed to load. Exiting ...', filename));
		return
	end
	
	% now load the 
	[filename, pathname_mov] = uigetfile(extension, 'Select the input (moving) image', pathname_fix);

    if filename == 0
        return;
	end
        
    [path, name_mov, ext] = fileparts(filename);
    mov_file = fullfile(pathname_mov, filename);
	
	% load the scf data from fixed_file
	scf_mov = struct2array(load(mov_file, '-mat', 'scf'));
	if ~isempty(scf_mov)
		disp(sprintf('Moving image %s successfully loaded.', filename));
	else
		disp(sprintf('Moving image %s failed to load. Exiting ...', filename));
		clear;
		return		
	end
	
	% now compute the transformation
	[tform, fd_fix, fd_mov] = palm_register_scf(scf_fix, scf_mov);
	
	% subsequent operations depend on the object mode. If no input, then simply exits.
	switch object
		case 2
			disp('Mode 2: Aligning moving image to fixed image and exporting to coloc-Tesseler csv files.');
			
			out_fix = fullfile(pathname_fix, [name_fix '.csv']);
			out_mov = fullfile(pathname_mov, [name_mov '.csv']);
			
			% apply transformation to the moving image scf
			scf_mov(:, 1:2) = transformPointsForward(tform, scf_mov(:, 1:2));
			
			% clean up the x, y values in transformed scf_mov 
			scf_mov = scf_mov(scf_mov(:, 1) > 0, :);
			scf_mov = scf_mov(scf_mov(:, 2) > 0, :);
			
			% export files
			palm_scf_to_ctcsv(scf_fix, out_fix);
			palm_scf_to_ctcsv(scf_mov, out_mov);
		
		case 1
			global params;
			disp('Mode 1: applying transformation to currently loaded image.');
			scf = params.scf;
			scf(:, 1:2) = transformPointsForward(tform, scf(:, 1:2));
			params.scf(:, 1:2) = scf(:, 1:2);
		case 0
			disp('Mode 0: only testing registration quality. no actions taken on the files.');
			pause(0.1);
	end
	
	clear;
	