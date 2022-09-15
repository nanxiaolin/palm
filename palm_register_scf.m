function [tform, fd_fix, fd_mov] = palm_register_scf(scf_fixed, scf_moving)
%
% tform = palmregister(scf_fixed, scf_moving)
%
% function that registered a moving palm image (scf_moving) to a fixed palm image (scf_fixed)
% by using built-in fiducials
% 
% returns the transformation matrix tform and matching pairs of fidicials fd_fix and fd_mov
% 
% 04/2022. Xiaolin Nan and Malwina Szczepaniak, OHSU
% Current method works for typical DNA-PAINT image alignment, where the images are only slightly 
% shifted due to translational and perhaps rotational movements but no significant changes in
% magnification or rotation.

	% first step is to identify the potential registration fiducials in the two datasets
	fd_fix = palm_findregfds( scf_fixed );
	fd_mov = palm_findregfds( scf_moving );
	
	% plot the two sets of fiducials
	%figure; plot(fd_fix(:, 1), fd_fix(:, 2), 'b+');
	%hold on; plot(fd_mov(:, 1), fd_mov(:, 2), 'r+');
	
	% calculate pairwise distances in the x and y directions
	%disp(sprintf("\nCalculating pairwise x and y distances ..."));
	len_mov = length(fd_mov);
	len_fix = length(fd_fix);
	dist_x = zeros(len_fix, len_mov);
	dist_y = zeros(len_fix, len_mov);
	
	for i = 1 : len_fix
		for j = 1 : len_mov
			dist_x(i, j) = fd_fix(i, 1) - fd_mov(j, 1);
			dist_y(i, j) = fd_fix(i, 2) - fd_mov(j, 2);
		end
	end
	
	% build histograms of distance values from which the most common distances can be determined
	bin_num = ceil(len_mov * len_fix);
	h = figure; hx = histogram(dist_x, round(bin_num));
	[max_ocur_x, max_index_x] = max(hx.Values);
	hold on; hy = histogram(dist_y, round(bin_num));
	[max_ocur_y, max_index_y] = max(hy.Values);
	
	low_dist_x = hx.BinEdges(max_index_x);
	low_dist_y = hy.BinEdges(max_index_y);
	high_dist_x = hx.BinEdges(max_index_x + 1);
	high_dist_y = hy.BinEdges(max_index_y + 1);
	%msg = sprintf("\nThe distance between matched pairs of fiducials is between %.1f and %.1f pixels in x and %.1f and %.1f pixels in y", low_dist_x, high_dist_x, low_dist_y, high_dist_y);
	%disp(msg);
	close(h);
	
	% use the most probable distance to pick the matching pairs of fiducials
	dist_f_sel = zeros(len_mov, len_fix);
	match_count = 0;
	match_pair = [];
	
	%figure; hold on;
	for i = 1 : len_fix
		for k = 1 : len_mov
			if (dist_x(i,k) >= low_dist_x) && (dist_x(i,k) <= high_dist_x) && (dist_y(i,k) >= low_dist_y) && (dist_y(i,k) <= high_dist_y)
				%dist_f_sel(i, k) = dst(i, k);
				%plot(fd_mov(k, 1), fd_mov(k, 2), 'b+');
				%plot(fd_fix(i, 1), fd_fix(i, 2), 'r+');
				
				match_count = match_count + 1;
				match_pair = [match_pair; i, k];
			end
		end
	end
	
	fd_fix = fd_fix(match_pair(:, 1), :);
	fd_mov = fd_mov(match_pair(:, 2), :);
	%plot(fd_fix(:, 1), fd_fix(:, 2), 'b+');
	%plot(fd_mov(:, 1), fd_mov(:, 2), 'k+');

	% now we have matching pairs of registration fiducials, calculate the transformation matrix.
	tform = fitgeotrans(fd_mov(:, 1:2), fd_fix(:, 1:2), 'affine');
	fd_mov_tm = transformPointsForward(tform, fd_mov(:, 1:2));
	
	% plot the transformed moving fiducials
	%plot(fd_mov_tm(:, 1), fd_mov_tm(:, 2), 'r+');
	%legend('Reference Fiducials', 'Moving Fiducials', 'Moving Fiducials after Registration');
	
	% calculate the error in fiducial mapping
	rms_x = sqrt(sum((fd_fix(:, 1) - fd_mov_tm(:, 1)).^2) / match_count);
	rms_y = sqrt(sum((fd_fix(:, 2) - fd_mov_tm(:, 2)).^2) / match_count);
	disp(sprintf("\nFound %d pairs of matching fiducials. Aligned with RMS (x, y) = (%.2f, %.2f) pixels", match_count, rms_x, rms_y));
	%title(msg);
	
	%box on; axis auto; axis equal;
	%drawnow();
return