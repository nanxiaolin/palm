function [scf, sort_order] = palmsort(object, event)
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
% Revision on 12/02/2011
%  changed the workflow from sort -> calculate to sort | calculate.
%  finding all the sorted particles with the same # may take a long time
%
% Revision on 12/24/2013
%  1. fixed a bug that leads to crippled sorting on data sets starting from arbitrary frames (thanks to 
%      Amy Bittle for testing this)
%  2. Working on adding GPU computing support to this essential function
% 
% Revision on 12/1/2014
%  Major revision to address performance issues.
%  Simplified workflow to walk through the list of particles instead of
%  using a frame-based algorithm
%  Sorting speed increased dramatically by ~50x
%
% Revision on 02/10/2020
%  Incorporated implementations of drift correction. Simply apply the
%  correction before the sorting starts.
%  Other revisions:
%  1. added an option to stop sorting once sorting has started
%  2. added options based on the 'event' code, where event == 0 means
%     sorting in the background, where the object is the handle for
%     displaying the progress of sorting. this allows scripts such as
%     driftcorrect to run a separate sorting process without affecting the
%     main scf and sort_order fields.
% 
% Revision on 02/27/2020
%  Now enables sorting within specific frame ranges. this facilitates 
%  identification of fiducial markers and is not intended for sorting 
%  specific frame ranges.


	global h_palmpanel handles params;
    
    % added in revision 02/10/20 - to allow silent calls as well as batch
    % processing (action = 'silent' and 'batch', respectively'
    % step 0, determine the source of the call
    switch event.EventName
        case 'Action'       % this is the callback from 'Sort' button
            stoppable = true;
            % all the messages will be shown on the main status bar
            h_msg = handles.txtMessage;
            % allow the results to be updated to params
            update_params = true;
            % allow the results to be saved to the cor file
            save_results = true;
            return_results = false;
            
            % the sorting parameters should come from the current form
            thresh  = str2double(get(handles.thresh, 'string'));
            preturn = str2double(get(handles.comframes, 'string'));
            pdist   = str2double(get(handles.comdist, 'string'));
            pixsize = str2double(get(handles.pixelsize, 'string'));
            min_goodness = str2double(get(handles.mingood, 'string'));
            max_eccentricity = str2double(get(handles.maxeccen, 'string'));
			frame_start = params.coords(1, 1);
			last_frame = params.frames + frame_start - 1;
            
        case 'Silent'       % silent call from other apps like driftcorrect
            stoppable = false;
            h_msg = object;     % this defines where the message will go
            update_params = false;
            save_results = false;
            return_results = true;
            
            % the sorting parameters should come from the Events structure
            thresh = event.thresh;
            preturn = event.preturn;
            pdist = event.pdist;
            pixsize = str2double(get(handles.pixelsize, 'string'));
            min_goodness = event.min_goodness;
            max_eccentricity = event.max_eccentricity;
			
			% note: here, frame_start counts from the first frame, which may have a frame # > 1
			first_frame = params.coords(1, 1);
			frame_start = event.fstart + first_frame - 1;
			last_frame = event.fend + first_frame - 1;
			
			if last_frame > (params.frames + params.coords(1,1) - 1)
				last_frame = params.frames + params.coords(1,1) - 1;
			end
            
        case 'Batch'
            % this is the mode that allows batch processing, in which case
            % there is msg update but no stop button nor params updates
            stoppable = false;
            h_msg = handles.txtMessage;
            update_params = false;
            save_results = true;
            return_results = false;
            
            % the sorting parameters should come from the Events structure
            thresh = event.thresh;
            preturn = event.preturn;
            pdist = event.pdist;
            pixsize = event.pixelsize;
            min_goodness = event.min_goodness;
            max_eccentricity = event.max_eccentricity;
			
			frame_start = params.coords(1, 1);
			last_frame = params.frames + params.coords(1,1) - 1;
    end
    
	update_status(h_msg, 'Preparing variables for sorting ...');   
	pause(0.02);
	
	pdist   = pdist / pixsize;		% convert the pdist units to pixels (always use pixels before final rendering)
	sort_order = zeros(length(params.coords), 1);		
	
	% this matrix will record particle number assignments in the same order as in coords matrix
	
	% 02/27/2020. added a frame range specifier here
	r = find(params.coords(:, 1) >= frame_start);
	temp_sorted = params.coords(r, :);	raw_ind = r;
	r = find(temp_sorted(:, 1) <= last_frame);
	temp_sorted = temp_sorted(r, :);	raw_ind = raw_ind(r);

	% step 2, generate a temp matrix which has all SNR greater than RMS threshold
	% rms = mean(params.coords(:, 7)); 		% average noise level
	snr = temp_sorted(:, 4) ./ temp_sorted(:, 7);
	%figure; hist(snr, 300); grid on;
	r = find(snr >= thresh);	
	temp_sorted = temp_sorted(r, :);	raw_ind = raw_ind(r);
    
    % apply the drift corrections to temp_sorted
	% the drift.x and drift.y fields do not have frame # info, therefore the f_num
	% is relative to the first frame
    if isfield(params, 'drift')
        % disp('sorting with drift corrections.');
        
        x_raw = temp_sorted(:, 2)';
        y_raw = temp_sorted(:, 3)';
		
		% f_num used by .drift.x and .drift.y starts from 1
        f_num = temp_sorted(:, 1) - params.coords(1, 1) + 1;	
        idx = 1 : length(x_raw); 
    
        % apply the corrections
        x_raw(idx) = x_raw(idx) - params.drift.x(f_num(idx));
        y_raw(idx) = y_raw(idx) - params.drift.y(f_num(idx));    
        
        % save the modified coordinates back to temp_sorted
        temp_sorted(:, 2) = x_raw';
        temp_sorted(:, 3) = y_raw';
    end
    
    
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
    raw_numparticles = length(r);

	% raw_ind records the original row # of the particles to be sorted
    
	% step 3, connect points that originate from the same particle by assigning field #8 as particle numbers
	% create a index matrix for fast reference to distance search
	frame_index = zeros(params.frames, 2);		% columns: start row - end row
	
	% particle sequence number
	particle_num = 0;
	%frame_start = params.coords(1, 1);
    last_frame = max(sorted(:, 1));
    sorted(:, 8) = 0; % all particles will be renumbered but their order in the matrix will remain the same
    
    % below are the matrices that will be stored in the sorted file
    % scf format: x, y, sum intensity, first frame that the particle appears (for particle tracking analysis)
    % 	scf(i, :) = [x_ave y_ave sum_int first_frame num_frames std_x std_y];
    
    scf = zeros(raw_numparticles, 7);
    temp = zeros(raw_numparticles, 2);      % temp array to store sum(x) and sum(y)
    
    update_status(h_msg, 'Preparing variables for sorting ... Done. Sorting started.');
    pause(0.2);
    
    % if stoppable, change the button 'Sort' to 'Stop' to allow cancellation 
    stopped = false;
    if stoppable 
        set(handles.palmsort, 'string', 'STOP', 'callback', @onstopsort);
    else
        set(handles.palmsort, 'enable', 'off');
    end
    
    % revision 12/01/2014: change to a particle based sorting mechanism
    for i = 1: raw_numparticles
        
        if (stopped == true)
            %whos
            % restore the button status
            set(handles.palmsort, 'string', 'Sort', 'callback', @palmsort);
            clear
            return;
        end
        
        cur_frame = sorted(i, 1);
        
        end_frame = cur_frame + preturn + 1;
        if end_frame > last_frame
            end_frame = last_frame;
        end
        
        % if this is a new particle, then assign a new particles # to it
        if sorted(i, 8) == 0
            particle_num = particle_num + 1;
            sorted(i, 8) = particle_num;
            
            ints = 2 * pi * sorted(i, 4) * sorted(i, 5) * sorted(i, 6); 
            scf(particle_num, 1) = sorted(i, 2) * ints;
            scf(particle_num, 2) = sorted(i, 3) * ints;
            scf(particle_num, 3) = ints;
            scf(particle_num, 4) = cur_frame;       % record the first frame
            scf(particle_num, 5) = 1;
            scf(particle_num, 6) = sorted(i, 2)^2;
            temp(particle_num, 1) = sorted(i, 2);
            scf(particle_num, 7) = sorted(i, 3)^2;
            temp(particle_num, 2) = sorted(i, 3);
        end
        
        pid = sorted(i, 8);
        sort_order(raw_ind(i)) = pid;
         
        if cur_frame < last_frame
            
            % locate the next frame
            j = i + 1;
            while(sorted(j, 1) <= cur_frame) j = j + 1; end        

            % these two variables are to record activities in each frame
            search_frame = cur_frame + 1;
            last_j = 0;         
            last_dist = 100;
            
            while sorted(j, 1) <= end_frame
            
                if sorted(j, 8) ~= 0 % the particle has already been counted before
                    if j < raw_numparticles
                        j = j + 1;
                        continue;
                    else
                        break;
                    end
                end
                
                if sorted(j, 1) > search_frame          % new frame, reset last_j and store the values     
                    if last_j ~= 0      % there was a particle in the last search frame, store the values
                        sorted(last_j, 8) = pid;

                         % add the values to the correct place within the scf matrix
                        ints = 2 * pi * sorted(last_j, 4) * sorted(last_j, 5) * sorted(last_j, 6);
                        scf(pid, 1) = scf(pid, 1) + sorted(last_j, 2) * ints;    % sum x * intensity
                        scf(pid, 2) = scf(pid, 2) + sorted(last_j, 3) * ints;    % sum y * intensity
                        scf(pid, 3) = scf(pid, 3) + ints;
                        scf(pid, 5) = scf(pid, 5) + 1;
                        
                        %if(pid == 4) disp(sprintf('Particle 4 counted again in frame %d', search_frame)); end

                        % for stdx and stdy: use this formula: var(x) = sum(x2) - n* (ave_x)^2)
                        scf(pid, 6)  = scf(pid, 6)  + sorted(last_j, 2)^2;
                        temp(pid, 1) = temp(pid, 1) + sorted(last_j, 2);
                        scf(pid, 7)  = scf(pid, 7)  + sorted(last_j, 3)^2;
                        temp(pid, 2) = temp(pid, 2) + sorted(last_j, 3);
                    end
                    
                    search_frame = sorted(j, 1);
                    last_j = 0;
                    last_dist = 100;
                end
                
                dist = sqrt((sorted(i, 2) - sorted(j, 2))^2 + (sorted(i, 3) - sorted(j, 3))^2);

                % found a potential candidate, but need to pick the best
                % among possibilities
                
                if dist <= pdist  % regard as the same particle
                    %msg = sprintf('found particle #%d in frame %d to be close to particle #%d in frame %d', j, sorted(j, 1), i, cur_frame);
                    %disp(msg);
                    if last_j == 0 || dist < last_dist  % first time in this frame
                        last_j = j;
                        last_dist = dist;
                    end
                end
 
                if j < raw_numparticles
                    j = j + 1;  
                else
                    break;
                end
            end
        end
        
        if mod(i, 1000) == 0	|| i == raw_numparticles || i == 1
 			msg = sprintf('Sorting particle %d', i);
 			update_status(h_msg, msg);
 			pause(0.001);		
 		end
    end
    
    % deal wit the last particle
%     if sorted(raw_numparticles, 8) == 0
%         particle_num = particle_num + 1;
%         sorted(raw_numpaticles, 8) = particle_num;
%         sort_order(raw_ind(raw_numparticles)) = particle_num;
%     end
    
    % clean up scf and calculate the ave_x, ave_y, and std_x and std_y
    scf = scf(1:particle_num, :);
    scf(1:particle_num, 1) = scf(1:particle_num, 1) ./ scf(1:particle_num, 3) ;
    scf(1:particle_num, 2) = scf(1:particle_num, 2) ./ scf(1:particle_num, 3) ;
    
    % calculate stdx and stdy using sum(x - d)2 = sum(x2) - 2*d*sum(x) +
    % sum(d2), where d is the intensity weighted average. sum(d2) = n*d2
    % sum_x2 is stored in column 6, n in 5, and d in 1
    % sum(x) is stored in the temp varaiable in column 1
    % stdy is similarly calculated
    sum_x2 = scf(1:particle_num, 6);
    dx = scf(1:particle_num, 1);
    sum_dx2 = scf(1:particle_num, 5) .* (scf(1:particle_num, 1) .^2);
    scf(1:particle_num, 6) = sqrt(abs(sum_x2 - 2 * (dx .* temp(1:particle_num, 1)) + sum_dx2));
    
    sum_y2 = scf(1:particle_num, 7);
    dy = scf(1:particle_num, 2);
    sum_dy2 = scf(1:particle_num, 5) .* (scf(1:particle_num, 2) .^2);
    scf(1:particle_num, 7) = sqrt(abs(sum_y2 - 2 * (dy .* temp(1:particle_num, 2)) + sum_dy2));
  
    %scf(1:particle_num, 1) = scf(1:particle_num, 1)  - params.xoff + 1;
    %scf(1:particle_num, 2) = scf(1:particle_num, 2)  - params.yoff + 1;
    
    
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
	
	msg = sprintf('Sorting finished. Preparing to save and/or update the results ...');
	update_status(h_msg, msg);

	if update_params
        set(handles.dispsorted, 'String', sprintf('%d', particle_num));
        pause(0.02);
    
        % commit changes to params
        params.scf = scf;
        params.sort_order = sort_order;
        params.is_sorted = 1;

        % now populate the sortpars a data structure that stores sorting parameters
        sortpars.pixelsize = pixsize;
        sortpars.pdist = str2num(get(handles.comdist, 'string'));
        sortpars.rms = thresh;
        sortpars.preturn = preturn;
        sortpars.goodness = min_goodness;
        sortpars.eccentric = max_eccentricity;

        params.sortpars = sortpars;
        
        % change the status of related buttons
        set(handles.renderpalm, 'enable', 'on');
        set(handles.palmstats, 'enable', 'on');
        set(handles.moviemode, 'enable', 'on', 'value', 0);
    else
        update_status(h_msg, 'Sorting finished. No changes made to the params structure.');
        pause(1);
    end
    
    if save_results
        % also save the .drift and the .fiducials fields
        drift = params.drift;
        fiducials = params.fiducials;

        % save the file (always leave the .coords part untoched. that is the raw data.)
        save(params.fullname, 'sortpars', 'scf', 'sort_order', 'drift', 'fiducials', '-APPEND');
        update_status(h_msg, 'Sorting finished. Results saved to file. Ready to RENDER.');
    else 
        update_status(h_msg, 'Sorting fishied. Results not saved to file.');
        pause(1);
    end

	% enable the 'render' button

    set(handles.palmsort, 'Enable', 'on', 'string', 'Sort', 'callback', @palmsort);
    
    if ~return_results % if not saveing the results then return scf and sort_order
        clear;
    end
    
    %%%%%%%%% function update_status %%%%%%%%%%%
    function update_status(h_msg, msg)
       if ~isempty(h_msg) && ~isempty(msg)
            set(h_msg, 'string', msg);
       end
    end
    %%%%%%%%%% end of update_status %%%%%%%%%%
    
    %%%%%%%%% function onstopsort %%%%%%%%%%%%
    function onstopsort(object, event)
       if stoppable
            stopped = true; 
       end
    end
    %%%%%%%%% end of onstopsort %%%%%%%%%%%%%%%
end
