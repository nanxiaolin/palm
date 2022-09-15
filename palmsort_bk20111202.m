function palmsort(object, event)
%
% palmsort: sorts particles based on spatial and temporal continuity.
% this function generates a .scf matrix in the userdata structure
% which can then be used to render a final PALM image.
%
% note: this potentially can be rewritten in C for faster speed
%
% Revision on 07/02/2010
%  added .sorted and .scf matrice saving to disk file
%  .sorted was originally used as a storage for sorted particles (not renderable yet)
%  now .sorted is a data structure that stores sortting parameters
%  .scf is the final sorted coordinat matrix
%  columns: [x y sum_intensity 1st_frame num_frames std(x) std(y)]
%
% Revision on 07/14/2010
%  removed .sorted and added .sort_pars structure and .sort_order matrices to the saved file
%  .sort_pars records the sorting parameters
%  .sort_order records the assignment to EACH raw particle in the same order as the .coords
%  this makes it very easy to track down which raw particles each 'sorted' particle corresponds to
%
% Revision on 08/05/2010
%  changed sum_intensity from simple addition of amplitudes to integrated intensity
%  same change applies to intensity weights when calculating the average particle position
%
% Revision on 
%  changed the workflow from sort -> calculate to sort | calculate.
%  finding all the sorted particles with the same # may take a long time
%  it is easier to 

	global h_palmpanel handles params;

	% step 1, read out the parameters: threshold; combine frames and distance
	thresh  = str2num(get(handles.thresh, 'string'));
    preturn = str2num(get(handles.comframes, 'string'));
	pdist   = str2num(get(handles.comdist, 'string'));
	pixsize = str2num(get(handles.pixelsize, 'string'));
	pdist   = pdist / pixsize;		% convert the pdist units to pixels (always use pixels before final rendering)
    min_goodness = str2num(get(handles.mingood, 'string'));
    max_eccentricity = str2num(get(handles.maxeccen, 'string'));

	sort_order = zeros(length(params.coords), 1);		
	% this matrix will record particle number assignments in the same order as in coords matrix
	
	% step 2, generate a temp matrix which has all SNR greater than RMS threshold
	rms = mean(params.coords(:, 7)); 		% average noise level
	snr = params.coords(:, 4) ./ params.coords(:, 7);
	%figure; hist(snr, 300); grid on;
	r = find(snr >= thresh);	raw_ind = r;
	temp_sorted = params.coords(r, :);

	% goodness filter
	r = find(temp_sorted(:, 8) <= min_goodness);
	temp_sorted = temp_sorted(r, :);
	raw_ind = raw_ind(r);

    % eccentricity filter
    eccentric = temp_sorted(:, 5) ./ temp_sorted(:, 6);

    r = find(eccentric <= max_eccentricity);
    temp_sorted = temp_sorted(r, :);
	raw_ind = raw_ind(r);
	
    eccentric = eccentric(r);
    r = find(eccentric >= (1.0/max_eccentricity));
    sorted = temp_sorted(r, :);
    clear temp_sorted;
    raw_ind = raw_ind(r);
    % raw_ind records the original row # of the particles to be sorted
    
	% step 3, connect points that originate from the same particle by assigning field #8 as particle numbers
	% create a index matrix for fast reference to distance search
	frame_index = zeros(params.frames, 2);		% columns: start row - end row
	
	% particle sequence number
	particle_num = 0;			
	
	%sorted(find(sorted(:, 1) <=6))
	for i = 1 : params.frames
		if mod(i, 100) == 0	|| i == params.frames || i == 1	
			msg = sprintf('Sorting frame %d', i);
			dispmessage(msg);
			pause(0.001);		
		end
		
		% get the indices of points within frame number i
		ind = find(sorted(:, 1) == i);
		pif = numel(ind);

		if pif == 0 
			continue
		end

		frame_index(i, 1) = min(ind);
		frame_index(i, 2) = max(ind);

		if i == 1		% first frame, assign particle numbers directly and continue
			sorted(1:pif, 8) = (1:pif)';
			particle_num = particle_num + pif;
			continue;
		end

		% determine a valid search range - a key step in fast sorting
		% search start : first frame in preturn frames back that is non-zeros (has particles)
		f_start = max(i - preturn, 1);		% start frame index in frame_index
		f_end   = i - 1;					% end frame index in frame_index
		s_range = find(frame_index(f_start : f_end, 1) > 0) + f_start - 1;
		
		if numel(s_range) == 0				% no particles in frames of search range
			sorted(ind, 8) = (particle_num + 1 : particle_num + pif)';
			particle_num = particle_num + pif;
			continue;
		end		

		s_start = frame_index(min(s_range), 1);
		s_end   = frame_index(max(s_range), 2);				
		x = sorted(s_start : s_end, 2);
		y = sorted(s_start : s_end, 3);
		
		for j = 1 : pif		% for each particle in frame, search for its counterpart in previous frames
			cur_point = frame_index(i, 1) + j - 1;		% index of current point in the sorted matrix
			x0 = sorted(cur_point, 2);			y0 = sorted(cur_point, 3);
			
			% calculate the distance matrix
			dist_mat = sqrt((x - x0).^2 + (y - y0).^2);

			% find out if the minimum distance is smaller than combinable distance
			[min_dist min_ind] = min(dist_mat);

			if min_dist <= pdist   % distance is very small, combine with previous point by giving the same num
				sorted(cur_point, 8) = sorted(s_start + min_ind - 1, 8);
			else				   % otherwise, make it a new num
				sorted(cur_point, 8) = particle_num + 1;
				particle_num = particle_num + 1;
			end
		end
	end

	%params.sorted = sorted;
	% combine coordinates of the same particles
	scf = zeros(particle_num, 7);		% x, y, reserved, reserved : 4/10/09

	%msg = sprintf('');
	%dispmessage(msg);
	%pause(0.001);	

	for i = 1 : particle_num
		if mod(i, 1000) == 0
			msg = sprintf('Generating particle coordinates ... %d / %d processed.', i, particle_num);
			dispmessage(msg);
			pause(0.01);
		end

		ind = find(sorted(:, 8) == i);
		num_frames = numel(ind);
		sort_order(raw_ind(ind)) = i;		% a good place to assign raw indices to original .coords particles

		% calculate the average coordinates as the intensity weighted mean x, y
		ints = 2*pi * sorted(ind, 4) .* sorted(ind, 5) .* sorted(ind, 6);
		sum_int = sum(ints);		% integrated intensity = 2*pi*sigx*sigy*amp
		first_frame = sorted(ind(1), 1);
		std_x = std(sorted(ind, 2));
		std_y = std(sorted(ind, 3));
		x_ave = sum(sorted(ind, 2) .* ints)/sum_int - params.xoff + 1;
		y_ave = sum(sorted(ind, 3) .* ints)/sum_int - params.yoff + 1;

		% scf format: x, y, sum intensity, first frame that the particle appears (for particle tracking analysis)
		scf(i, :) = [x_ave y_ave sum_int first_frame num_frames std_x std_y];
	end
	
	% revision on 08/05/2010: added estimation of std_x and std_y on particles with num_frames == 1 (std_x = std_y = 0.707 * err)
	%ind = find(scf(:, 5) > 1);
	%y = sqrt(scf(ind, 6) .^2 + scf(ind, 7) .^2) ./ sqrt(scf(ind, 5));	% error
	%x = 1 ./ sqrt(scf(ind, 3));		% average summed intensity
	%b = sum(x .* y) / sum(x .* x)
	%a = mean(y - b * x)
	%scf(ind, 6) = scf(ind, 6) ./ sqrt(scf(ind, 5));
	%scf(ind, 7) = scf(ind, 7) ./ sqrt(scf(ind, 5));
	%ind = find(scf(:, 5) == 1);
	%scf(ind, 6) = 0.707* (b * 1./sqrt(scf(ind, 3)) + a);
	%scf(ind, 7) = scf(ind, 6);
	% this does not work as expected.
	
	msg = sprintf('Generating coordinates for particles. Please wait ... Done');
	dispmessage(msg);
	pause(0.001);	
	set(handles.dispsorted, 'String', sprintf('%d', particle_num));

	% commit changes to the userdata structure
	params.scf = scf;
	params.sort_order = sort_order;

	% now populate the sortpars a data structure that stores sorting parameters
	clear sorted;
	sortpars.pixelsize = pixsize;
	sortpars.pdist = str2num(get(handles.comdist, 'string'));
	sortpars.rms = thresh;
	sortpars.preturn = preturn;
	sortpars.goodness = min_goodness;
	sortpars.eccentric = max_eccentricity;

	params.sortpars = sortpars;
	fullname = params.fullname;

	% save the file (always leave the .coords part untoched. that is the raw data.)
	save(params.fullname, 'sortpars', 'scf', 'sort_order', '-APPEND');

	dispmessage('Sorting finished. Results saved to file. Ready to RENDER.');

	% enable the 'render' button
	set(handles.renderpalm, 'enable', 'on');
    set(handles.palmstats, 'enable', 'on');
return
