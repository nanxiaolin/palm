function reg_fds = palm_findregfds( scf )
%
% reg_fds = palm_findregfds (scf)
%
% Function palm_findregfds uses the input sorted coordinates (scf) to identify potential registration fiducials.
% Returns all potential fiducials but combines multiple incidences of the same fds. the positions will be (duration)
% weighted average of all incidences.
% 
% Returns reg_fds, an Nx3 array with (x, y, rms) positions of the N markers (empty array if N = 0).
%
% This function assumes that drift corretion has been applied.
%
% First developed on 04/2022 based on sections from palmrender. Xiaolin Nan, OHSU.

	%%%%%%%%%%%%%%%%% code begins %%%%%%%%%%%%%%%
	% reference - 
	% 	for 2D scf arrays, the columns are:	
	% 	[x_ave, y_ave, sum_int, first_frame, num_frames, std_x, std_y]
 
	% workflow:
	% 1. locate all incidences of potential fiducials (lasting >1000 frames)
	% 2. examine these incidences and combine them if they happen to be close
	% 	 the combining can be done by doing duration weighted positional average
	% 3. will also calulate the positional fluctuation of each fiducials
	%    so the calling function can filter the fiducials based ont he RMS value
	
	max_frame_num = max(scf(:, 4));
	min_frames = 1000;
	max_dist = 1;		% allowable distance before combining two candidate fiducials
	
	if min_frames > 0.5*max_frame_num
		min_frames = 0.5*max_frame_num;
	end
	
	% generate a list of raw fds
	idx = find(scf(:, 5) > min_frames);
	raw_fds = scf(idx, :);
	num_raw_fds = length(idx);
	
	% plot out the raw fiducials
	%h = figure; plot(raw_fds(:, 1), raw_fds(:, 2), 'b.');
	
	% the fd_id array holds particle IDs -> for use when combining positions of particles of the same id
	fd_id = zeros(num_raw_fds, 1);
	fd_count = 0;
	
	for i = 1: num_raw_fds
		% look at unassigned particles only
		if fd_id(i) == 0
			xi = raw_fds(i, 1);
			yi = raw_fds(i, 2);
			
			dst = sqrt((xi - raw_fds(:, 1)).^2 + (yi - raw_fds(:, 2)).^2);
			
			same_idx = find(dst < max_dist);

			% sanity check to see if any of the fds in same_idx has already been assigned
			if length(find(fd_id(same_idx) ~= 0))>0
				disp('Some particles dually assigned');
			end
			
			fd_count = fd_count + 1;
			fd_id(same_idx) = fd_count;
			

			% print out a debugging message
			%msg = sprintf("\n%d candidate fiducials are combined into new particle #%d", length(same_idx), fd_count);
			%disp(msg);
		end
	end
	
	% now combine the fiducials based on fd_id and calculate the average positions and RMS.
	reg_fds = zeros(fd_count, 3);
	for j = 1 : fd_count
		reg_idx = find(fd_id == j);
		x = raw_fds(reg_idx, 1);
		y = raw_fds(reg_idx, 2);
		f = raw_fds(reg_idx, 4);
		sum_f = sum(f);
		
		% position x and y are duration weighted average
		% RMS is the positional fluctuation (small RMS may not indicate a good fiducial)
		reg_fds(j, 1) = sum(x .* f) / sum_f;
		reg_fds(j, 2) = sum(y .* f) / sum_f;
		reg_fds(j, 3) = sqrt(std(x).^2 + std(y).^2);
	end
	
	%figure(h); hold on; plot(reg_fds(:, 1), reg_fds(:, 2), 'r+');
	%axis auto; box on; axis equal;
	
	return