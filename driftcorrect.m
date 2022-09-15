function driftcorrect(object, event)
% 
% Function for locating and applying fiducial markers in palm
% 
% Note: new format (structure) containing the
% following fields
%   fiducials.total (total number of potential fiducials)
%   fiducials.picked (fiducials that have been picked; 0 = no; 1 = yes)
%   fiducials.applied 
%       0: the current fiducials have not been applied yet
%       1: the current fiducials have been applied to the sorted (.scf)
%       2: the current fiducials have been applied to the unsorted
%       (.coords) - will need to unapply before modifying the fiducials
%   fiducials.pids (type of fiducials)
%       0: pre-defined. do not delete these (only in old .cor files)
%       1: found by 'search fiducials' function
%       2: virtual fiducials based on computational analysis
%   fiducials.coords (x,y,sigx,sigy,int); n*frame*5
% 
% initial version on 02/10/2020. Xiaolin Nan (c) OHSU. current version only
% handles 2D drift corrections.
%
% revision on 02/29/2020 (Xiaolin Nan). Changed algorithm for automatic fiducial
% search using a more efficient and robust algorithm than the previous one that
% solely depend on sorting.
%
% revision on 05/20/2021 (Xiaolin Nan). Added criterion for good candidate
% fiducials, so erratic ones are no longer added to the list.
% 
% revision on 08/27/2022 (Xiaolin Nan). Added filtering mechanisms to pick
% the top 100 fiducials when there are >100 in a single FOV


	global h_palmpanel handles params;
    
    % set the median filter size
    size_mfilter = 51;

    % load the drift correction UI
    p = fileparts(mfilename('fullpath'));
    
    % close the drift correction window accidentally left open
    if handles.figdrift ~= -1
        onfigdriftclosed();
    end
    
    handles.figdrift = open([p '/fig/driftcorrection.fig']);

    % disable the drift corr button
    set(handles.driftcorr, 'enable', 'off', 'units', 'pixels');
    set(handles.figdrift, 'CloseRequestFcn', @onfigdriftclosed);
    set(h_palmpanel, 'units', 'pixels');
    
    % adjust the window position to be next to the main panel
    main_pos = get(h_palmpanel, 'Position');
    fig_pos = get(handles.figdrift, 'Position');
    set(handles.figdrift, 'Position', ...
                [main_pos(1)-50 main_pos(2)-50 fig_pos(3) fig_pos(4)]);
    
    % assign the correct functions to the three buttons
    % get all the handles (drift correction handles, or dch)
    dch = guihandles(handles.figdrift);
    set(dch.btnClose, 'callback', @onfigdriftclosed);
    set(dch.btnFind, 'callback', @findfiducials);
    set(dch.btnApply, 'callback', @applyfiducials);
    set(dch.btnPick, 'callback', @pickfiducials);
    set(dch.btnUnapply, 'callback', @unapplyfiducials);
    set(dch.btnUnpick, 'callback', @unpickfiducials);
    set(dch.lstFiducials, 'callback', @onfiducialclick);

    box on; grid on;

    % populate the fiducials fields
    populate_list;
    check_apply;
    mark_sumimage([]);
    
    
%% function findfiducials %%
    function findfiducials(~, ~)
    % function that locates potential fiducials
    % the workflow is to:
    % 1. perform a silent cor sorting using large preturn value to locate
    %    all potential markers that last >40% (or at least 1,000) frames;
    % 2. stores all the fiducials in the .fiducials list and mark the pids
    %    as 1 (found by the findfucials function - real fiducials)

        % set a few variables for defining fiducials. these may be
        % incoroporated into UI forms in the future
        min_fraction = 0.50;
        
        h_msg = dch.DCstatus;
        ff_event.EventName = 'Silent';
        ff_event.preturn = 5;
        ff_event.pixsize = str2double(get(handles.pixelsize, 'string'));
        ff_event.pdist = ff_event.pixsize;		
        ff_event.min_goodness = 0.25;
        ff_event.max_eccentricity = 1.6;
        ff_event.thresh = 3;
		ff_event.fstart = 1;
		ff_event.fend = 500;
        ff_event.drift_correct = false;
		bad_thresh = 0.25;		% threshold for fraction of time a particle is lost
        
		msg = sprintf('Analzying the first %d frames of particle coordinates ...', ff_event.fend - ff_event.fstart + 1);
        update_DCstatus(msg);
        pause(0.1);
        [scf, sort_order] = palmsort(h_msg, ff_event);
        
		% scf format:
		% 	scf(i, :) = [x_ave y_ave sum_int first_frame num_frames std_x std_y];
		% sort_order:
		%	each element is the new particle ID for the same particle in raw coords (the same order)
		
        % now check the sort_order to identify potential fiducials
		min_frames = round((ff_event.fend - ff_event.fstart + 1) * min_fraction);
        idx = find(scf(:, 5) >= min_frames);
        num_fds = numel(idx);   					% number of potential fiducials
		num_raw = numel(params.coords(:, 1));		% number of raw particles
        
		update_DCstatus(sprintf('Found %d particles potentially usable as fiducials.', num_fds));
		pause(0.1);
		%figure(h_palmpanel); hold on; axis on;
		%figure(h_palmpanel); plot(scf(idx, 1), scf(idx, 2), 'gs', 'MarkerSize', 8);
				
		% for each potential fd, calculate a distance matrix with all particles in the list
		fd_coords = zeros(num_fds, params.frames, 2);	% the fd trajectories
		is_good = ones(1, num_fds);					% whether the current fiducial is good
		all_x = params.coords(:, 2);								% x coord of all raw
		all_y = params.coords(:, 3);								% y coord of all raw
		fids  = params.coords(:, 1) - params.coords(1, 1) + 1;		% corrected frame #

		for i = 1 : num_fds	
			% starting from the first 20 frames
			raw_ids = find(sort_order == idx(i));
			first_fid = scf(idx(i), 4);
			cur_x = mean(params.coords(raw_ids(1:20), 2));
			cur_y = mean(params.coords(raw_ids(1:20), 3));

			update_DCstatus(sprintf('Processing fiducial candidate #%d (of %d) at (%.0f, %.0f)', i, num_fds, cur_x, cur_y));
			pause(0.05);
			%whos
			cur_frame = 1;
			j = 1;
			bad_frames = 0;
			
			while j < num_raw
				min_dist = 100;
				min_j = j;
				
				while(fids(j) == cur_frame)	
					dist = sqrt((cur_x - all_x(j))^2 + (cur_y - all_y(j))^2);
					
					if dist < min_dist
						min_dist = dist;
						min_j = j;
					end
					
					if j == num_raw
						%disp(sprintf('Reached the end of search for particle %d at j=%d.\n', i, j));
						j = j + 1;
						break;
					else
						j = j + 1;
					end	
				end
				
				if min_dist < 1
					fd_coords(i, cur_frame, 1) = all_x(min_j);
					fd_coords(i, cur_frame, 2) = all_y(min_j);
					
					if cur_frame < 50
						cur_x = mean(fd_coords(i, 1:cur_frame, 1));
						cur_y = mean(fd_coords(i, 1:cur_frame, 2));
					else
						cur_x = mean(fd_coords(i, cur_frame-49:cur_frame, 1));
						cur_y = mean(fd_coords(i, cur_frame-49:cur_frame, 2));
					end
					
					%good_frames = good_frames + 1;
				else
					if cur_frame == 1
						fd_coords(i, cur_frame, 1) = cur_x;
						fd_coords(i, cur_frame, 2) = cur_y;
					else 
						% cannot locate the particle in the current frame - use previous coordinates
						fd_coords(i, cur_frame, 1:2) = fd_coords(i, cur_frame - 1, 1:2);
						bad_frames = bad_frames + 1;
					end
				end
				
				if bad_frames >= bad_thresh * params.frames 	% too many bad frames
					is_good(i) = 0;
					break;
				end
				
				if (cur_frame < params.frames)
					cur_frame = cur_frame + 1;
				end	
			end
			
			% show on the console how many frames are good for the current fiducial
			if is_good(i)
				%disp(sprintf('Particle #%d is a valid fiducial.', i));
			
				% smooth the fd_coords with medfilt1 using a mild filter size
				fd_coords(i, :, 1) = medfilt1(fd_coords(i, :, 1), 21);
				fd_coords(i, :, 2) = medfilt1(fd_coords(i, :, 2), 21);

                % use is_good(i) to record the percentage of good frames
                is_good(i) = 1.0 - bad_frames / params.frames;
			else
				%disp(sprintf('Particle #%d is not a valid fiducial.', i));
			end
			
			%num_zeros = numel(find(fd_coords(i, :, 1:2) == 0));
			%update_DCstatus(sprintf('Fiducial #%d has %d good frames with %d unfilled frames.', i, good_frames, num_zeros));
			%pause(0.05);
		end
		
		% filter the fiducials based on is_good results
		good_fds = find(is_good > 0);	% indices of good fiducials
		if isempty(good_fds)
			num_fds= 0;
			
			params.fiducials.total = 0;
			params.fiducials.picked = [];
			params.fiducials.pids = [];
			params.fiducials.coords = [];
			params.fiducials.applied = 0;
		else
			num_fds = numel(good_fds);
            fd_coords(1:num_fds, :, 1:2) = fd_coords(good_fds, :, 1:2);

            % if too many fds, then filter them based on is_good score
            if num_fds > 100
                update_DCstatus('More than 100 candidate fiducials found. Keeping the best 99.');
                pause(0.1);

                is_good = is_good(good_fds);
                [~, sort_idx] = sort(is_good, 'descend');
                selected = sort_idx(1:99);
                num_fds = 99;
                fd_coords(1:num_fds, :, 1:2) = fd_coords(selected, :, 1:2);
            end
			
			% now all the fiducial coords have been populated, update the fiducials field
			params.fiducials.total = num_fds;
			params.fiducials.picked = zeros(num_fds, 1);
			params.fiducials.pids = ones(num_fds, 1);
			params.fiducials.coords = fd_coords(1:num_fds, :, 1:2);
			params.fiducials.applied = 0;
		end
		
        if num_fds > 1
            % now the fiducials are in place, perform a 2D correlation analysis
            % to identify which pair(s) are the best correlated.
            update_DCstatus('Performing correlation analysis on the potential fiducials ...');
            pause(1);
            fd_rms = zeros(num_fds, num_fds);
            for i = 1:num_fds
                for j = 1:num_fds
					if (i ~= j)
						fd_rms(i,j) = sqrt(std(fd_coords(i,:,1) - fd_coords(j,:,1)).^2 + std(fd_coords(i,:, 2)-fd_coords(j,:,2)).^2);
					else
                        fd_rms(i,j) = 65535;
                    end
                end
            end

			%params.fiducials.fdcor = fdcor;
			% now look for the best pair and pick them in the list
			[m, ind1] = min(fd_rms);
			[~, ind2] = min(m);
			min_i = ind2; min_j = ind1(ind2);

			% put the particle #s in order
			if min_i > min_j
				tempi = min_i;
				min_i = min_j;
				min_j = tempi;
			end

			msg = sprintf('Fiducials #%d and #%d have been picked as the best pair.', min_i, min_j);
			update_DCstatus(msg);
			pause(0.2);        
			params.fiducials.picked(:) = 0;
			params.fiducials.picked(min_i) = 1;
			params.fiducials.picked(min_j) = 1;
        else % no fiducials found. make no changes to the fiducials nor drift
            update_DCstatus('Did not find any new fiducials. Exiting ...');
            pause(0.1);
        end
        
        populate_list;
        mark_sumimage;
    end
    %%%%%%% end of findfiducials %%%%%%
    
    
%% function applyfiducials  %%%%%%%%%%%%%%

    function unapplyfiducials(object, event)
    % function that unapplies the current set of fiducials
    % usually this simply involves re-calculation of the .scf
    % since the raw .coords remains 'uncorrected'
    % except that when fiducials have been pre-applied to the raw .coords
    % which applies to older datasets (where .applied = 2)
        if params.fiducials.applied == 2    % this is to unapply to raw
            resp = questdlg('This action will remove (x, y) drift corrections previously applied to the RAW dataset. Are you sure?', ...
                            'Confirming modification to raw data');
            switch resp
                case 'No'
                    return;
                case 'Cancel'
                    return;
                case 'Yes'  % bring raw data to previous state
                    % calculate the (x, y) drift trajectories 
                    % using the same algorithm as in onmarker in wfiread
                    % all marker positions are simply averaged
                    % and filtered using medfilter1(traj, 2)
                    x_ave = mean(params.fiducials.coords(:, :, 1), 1);
                    y_ave = mean(params.fiducials.coords(:, :, 2), 1);
                    
                    % center the drift trajectories around 0
                    x_drift = medfilt1(x_ave - mean(x_ave), 2)';
                    y_drift = medfilt1(y_ave - mean(y_ave), 2)';
                    
                    %whos 
                    x_raw = params.coords(:, 2);
                    y_raw = params.coords(:, 3);
                    f_num = params.coords(:, 1);
                    idx = 1 : length(x_raw);
                    
                    % reverse the drift corrections                    
                    update_DCstatus('Starting raw coordinate reversion ...');
                    pause(0.1);
                    
                    x_raw(idx) = x_raw(idx) + x_drift(f_num(idx));
                    y_raw(idx) = y_raw(idx) + y_drift(f_num(idx));
                    
                    % update the raw coordinates
                    params.coords(:, 2) = x_raw;
                    params.coords(:, 3) = y_raw;
                    
                    % update the .fiducials field
                    params.fiducials.applied = 0;
                    
                    % clear the .drift field (to contain 0s)
                    params.drift.x = zeros(1, params.frames);
                    params.drift.y = zeros(1, params.frames);
                    
                    %
                    % save the new coordinates to the data file
                    % first load the file
                    s = load(params.fullname, '-MAT');
                    coords = s.coords; 
                    coords(idx+1, 2) = x_raw;
                    coords(idx+1, 3) = y_raw;
                    save(params.fullname, 'coords', '-APPEND');
                    
                    update_DCstatus('Starting raw coordinate reversion ... done. Results saved to file. Please re-sort the cor file.');
                    pause(0.1);
                    clear s coords;
            end
        else
            % in the new format, simply update params.drift fields
            params.drift.x = zeros(1, params.frames);
            params.drift.y = zeros(1, params.frames);
            
            params.fiducials.applied = 0;
        end
        
        % post-processing steps
        dch.btnUnapply.Enable = 'off';
        
        % apply the drift corrections                    
        update_DCstatus('Reverted fiducial corrections. Updating the sum image ...');
        pause(0.05);        
        showsumimage;
        mark_sumimage;
        
        dch.btnApply.Enable = 'on';
        
        % disable the render button
        handles.renderpalm.Enable = 'off';       
        
        % save the results and clear the .scf and .is_sorted 
        params.scf = [];
        params.is_sorted = 0;
        scf = []; sort_order = [];
        fiducials = params.fiducials;
        drift = params.drift;
        save(params.fullname, 'fiducials', 'drift', 'scf', 'sort_order', '-APPEND');
        
        clear scf is_sorted drift fiducials        
        update_DCstatus('Removed drift corrections. Please sort again before rendering.');
        pause(0.05);           
    end
    %%%%%%%%%%%%% end of unapplyfiducials %%%%%%%%%%%%%%%%
    
%% %%%%%%% function applyfiducials  %%%%%%%%%%%%%%
%
    function applyfiducials(object, event)
    % function that applies the currently selected fiducials.
    % this simply involves updating the .drift field using information
    % stored in the .fiducials field.
    % after such, a call to update the .scf and .sumimage will reflect the
    % updated drifts
    %
    % note that the .drift subfield will always be used during sorting, so
    % after unapplying the drifts, the .drift.x and drift.y fields will
    % just be cleared to contain zeros.
    % 
    % whereas the fiducials.applied field indicates whether the current
    % picked fiducials have been applied. everytime the fiducials are
    % changed they need to be re-applied, in which case the .drift field
    % will be updated.
    
        % calculate the average trajectories of the selected fiducaries
        pk_ids = find(params.fiducials.picked == 1);
        
        if isempty(pk_ids) % no fiducials picked, equal to unapply
            params.drift.x = zeros(1, params.frames);
            params.drift.y = zeros(1, params.frames);
            
            params.fiducials.applied = 0;
            
            % turn off both Appy and Unapply buttons
            dch.btnApply.Enable = 'off';
            dch.btnUnapply.Enable = 'off';
            update_DCstatus('Reverting drift correction since no fiducials picked. Now updating the sum image ...');
            
            % update the sum image
            pause(0.05);
            showsumimage;
            update_DCstatus('Drift correction reverted. Please pick fiducials and sort again.');
            pause(0.05);
        else
        
            x_ave = mean(params.fiducials.coords(pk_ids, :, 1) - params.fiducials.coords(pk_ids, 1, 1), 1);
            y_ave = mean(params.fiducials.coords(pk_ids, :, 2) - params.fiducials.coords(pk_ids, 1, 2), 1);

            % center the drift trajectories around 0
            params.drift.x = medfilt1(x_ave - mean(x_ave), size_mfilter);
            params.drift.y = medfilt1(y_ave - mean(y_ave), size_mfilter);
        
            %whos params.drift
            % post-processing
            params.fiducials.applied = 1;
            dch.btnApply.Enable = 'off';        
            update_DCstatus('Drift correction applied. Now updating the sum image ...');        
            
            % update the sum image
            pause(0.05);
            showsumimage;
            mark_sumimage;
            update_DCstatus('Drift correction applied. Please sort the cor file again before rendering.');
            pause(0.05);            
            dch.btnUnapply.Enable = 'on';        
        end
        
        % disable the render button
        handles.renderpalm.Enable = 'off';
        
        % save the results and clear the .scf and .is_sorted 
        params.scf = [];
        params.is_sorted = 0;
        scf = []; sort_order = [];
        fiducials = params.fiducials;
        drift = params.drift;
        save(params.fullname, 'fiducials', 'drift', 'scf', 'sort_order', '-APPEND');
        
        clear scf is_sorted drift fiducials
    end
    %%%%%%%%%%%%% end of applyfiducials %%%%%%%%%%%%%%%%
    
    %%
    %%%%%%%%%%%%% function pickfiducials %%%%%%%%%%%%%%%%
    function pickfiducials ( object, event )
    % this function adds the currently selected fiducial to the
    % picked fiducials list
        pk_ids = dch.lstFiducials.Value;
        
        if isempty(pk_ids)
            % something went wrong - the buttons should not be activated
            dch.btnPick.Enable = 'off';
            dch.btnUnpick.Enable = 'off';
        else
            is_picked = 0;
            
            for i = pk_ids
                if params.fiducials.picked(i) == 0
                    is_picked = is_picked + 1;
                    params.fiducials.picked(i) = 1;
                end
            end
            
            if is_picked == 0   % no new fiducials picked
                return;
            else
                % re-populate the list
                populate_list;
                
                % put the latest selections back
                dch.lstFiducials.Value = pk_ids;
                
                % re-draw the plots
                plotfiducials(pk_ids);
                
                % update the buttons
                dch.btnPick.Enable = 'off';
                dch.btnUnpick.Enable = 'on';
                dch.btnApply.Enable = 'on';
                
                % mark the current picked marker set as not applied
                params.fiducials.applied = 0;
            end
        end
        
        update_MSD;
        check_apply;
    end
    %%%%%%%%%%%%% end of pickfiducials %%%%%%%%%%%%%%%%%%
    
    %%
    %%%%%%%%%%%%% function unpickfiducials %%%%%%%%%%%%%%%%
    function unpickfiducials ( object, event )
    % this function removes the currently selected fiducial from the
    % picked fiducials list
        upk_ids = dch.lstFiducials.Value;
        
        % make sure this is a valid call
        if isempty(upk_ids)
            % something went wrong - the buttons should not be activated
            dch.btnPick.Enable = 'off';
            dch.btnUnpick.Enable = 'off';
            return
        else
            is_unpicked = 0;
            
            for i = upk_ids
                % only unpick the ones that are currently picked
                if params.fiducials.picked(i) == 1              
                    is_unpicked = is_unpicked + 1; 
                    params.fiducials.picked(i) = 0;
                end
            end
            
            %disp(sprintf("%d particles unpicked."), is_unpicked);
            
            if is_unpicked == 0
                return;
            else
                % re-populate the form
                populate_list;
                
                % put the last selections back
                dch.lstFiducials.Value = upk_ids;
                
                % re-draw the plots
                plotfiducials(upk_ids);
                
                % update button status
                dch.btnPick.Enable = 'on';
                dch.btnUnpick.Enable = 'off';
                dch.btnApply.Enable = 'on';
                
                % mark the current picked marker set as not applied
                params.fiducials.applied = 0;
            end
        end
        
        update_MSD;
        check_apply;
    end
    %%%%%%%%%%%%% end of unpickfiducials %%%%%%%%%%%%%%%%%%
    
    %%
    %%%%%%%%%%%%% function plotfiducials %%%%%%%%%%%%%%%%
    function plotfiducials(fids)
    % this function plots the trajectories of the 
    % fiducials selected in the list. when nothing is
    % selected, then it clears the plots

        if isempty(fids)
            update_DCstatus('Pick a fiducial to see the plots.');
        else
            % draw the marks on the sum image
            mark_sumimage(fids);
            
            figure(handles.figdrift);
            
            % subplot 1: draw raw (x,y) position
            pos1 = [0.25 0.48 0.21 0.26];
            h_plot1 = subplot('Position', pos1);
            
            % subplot 2: draw raw (displacement, frames)
            pos2 = [0.55 0.48 0.42 0.26];
            h_plot2 = subplot('Position', pos2);            

            % subplot 3: draw raw (displacement, frames)
            pos3 = [0.25 0.10 0.21 0.26];
            h_plot3 = subplot('Position', pos3);        

            % subplot 4: draw raw (displacement, frames)
            pos4 = [0.55 0.10 0.42 0.26];
            h_plot4 = subplot('Position', pos4);            

            % calculate the averaged (x, y) for all picked fiducials
            picked_ids = find(params.fiducials.picked == 1);
            
            if isempty(picked_ids)  % no fiducials picked yet
                %disp('no fiducials picked');
                x_picked = zeros(1, params.frames);
                y_picked = zeros(1, params.frames);
            else
                x_picked = mean(params.fiducials.coords(picked_ids, :, 1) - params.fiducials.coords(picked_ids, 1, 1), 1);
                y_picked = mean(params.fiducials.coords(picked_ids, :, 2) - params.fiducials.coords(picked_ids, 1, 2), 1);
                x_picked = medfilt1(x_picked, size_mfilter);
                y_picked = medfilt1(y_picked, size_mfilter);
            end
            
            % axis limits (default is +/- 0.5 pixel)
            ax1_lim = 0.25;
            ax3_lim = 0.2;
            ax4_lim = 0.15;
            for i = fids
               x = params.fiducials.coords(i, :, 1) - params.fiducials.coords(i, 1, 1);
               y = params.fiducials.coords(i, :, 2) - params.fiducials.coords(i, 1, 2);
               
               % sub plot 1 (x, y) centered around (0,0)
			   x_raw = x - mean(x);	y_raw = y - mean(y);
               plot(h_plot1, x_raw, y_raw); 
               hold(h_plot1, 'on');
               %find out the axis limits
               temp = 3 * median(abs(x_raw) + abs(y_raw));
               if ax1_lim < temp
                   ax1_lim = temp;
               end
               
               % calculate the corrected (x, y) centered around (0,0)
               x_cor = x - x_picked;
               y_cor = y - y_picked;
               plot(h_plot3, x_cor - mean(x_cor), y_cor - mean(y_cor));
               hold(h_plot3, 'on');
               temp = 4 * median(abs(x_cor) + abs(y_cor));
               if ax3_lim < temp
                   ax3_lim = temp;
               end
               
               % calculate the raw displacement trajectories
               disp_raw = sqrt(x.^2 + y.^2);
               plot(h_plot2, 1:length(disp_raw), disp_raw);
               hold(h_plot2, 'on');
               
               x_cor = x - x_picked;
               y_cor = y - y_picked;               
               % calculate the corrected displacement trajectories
               disp_cor = sqrt(x_cor .^2 + y_cor.^2);
               %disp_cor(1) = disp_cor(2);
               %disp_cor = disp_cor - mean(disp_cor);
               temp = 2 * std(disp_cor);
               if ax4_lim < temp
                   ax4_lim = temp;
               end
               plot(h_plot4, 1:length(disp_cor), disp_cor);
               hold(h_plot4, 'on');               
            end
            
            % create legends for the figures
            legstr = cellstr(reshape(sprintf('%3i', fids),3,[])');
            
            set(handles.figdrift, 'currentAxes', h_plot1);
            xlabel('x Drift (pixel)');
            ylabel('y Drift (pixel)');
            xlim([-ax1_lim ax1_lim]);
            ylim([-ax1_lim ax1_lim]);  
            title('(x, y) before correction');            
            set(gca, 'FontSize', 7);
            grid on; box on; hold(h_plot1, 'off');
            
			set(handles.figdrift, 'currentAxes', h_plot4);
            xlabel('Frame number');
            ylabel('Displacement (pixel)');            
            title('Displacement after correction');
            xlim([1 params.frames]);    
            ylim([-0.5*ax4_lim 3*ax4_lim]);
            legend(legstr, 'location', 'best');
            set(gca, 'FontSize', 7);
            grid on; box on; hold(h_plot4, 'off');            			
			
            set(handles.figdrift, 'currentAxes', h_plot2);
			if ~isempty(picked_ids)
				disp_picked = sqrt(x_picked .^2 + y_picked .^2);
				plot(h_plot2, 1:length(disp_picked), disp_picked, 'LineWidth', 2);
				
				legstr{numel(legstr) + 1} = '  Drift';
			end
            xlabel('Frame number');
            ylabel('Displacement (pixel)');            
            xlim([1 params.frames]);
            title('Displacement before correction');
            set(gca, 'FontSize', 7);
			legend(legstr, 'location', 'southeast');
            grid on; box on; hold(h_plot2, 'off');
            
            set(handles.figdrift, 'currentAxes', h_plot3);
            xlabel('x Drift (pixel)');
            ylabel('y Drift (pixel)');
            xlim([-ax3_lim ax3_lim]);
            ylim([-ax3_lim ax3_lim]);      
            title('(x, y) after correction');
            set(gca, 'FontSize', 7);
            grid on; box on; hold(h_plot3, 'off');         
        end
    end
    %%%%%%%%%%%%%% end of plotfiducials %%%%%%%%%%%%%%
    
    %%
    %%%%%%%%%%%%%%% function mark_sumimage %%%%%%%%%%%%%%%
    function mark_sumimage(fids)
    % function that marks the positions of the selected and the picked
    % fiducials on the sum image
        % initiate the respective handles subfield for storing the graphic
        % handles
        
        if nargin == 0  % no fids in put
            if params.fiducials.total == 0
                fids = [];
            else
                fids = 1:params.fiducials.total;
            end
        end
        
        % first draw the picked markers
        pk_ids = find(params.fiducials.picked == 1);
        
        if ~isempty(pk_ids)
            x_ave = mean(params.fiducials.coords(pk_ids, :, 1) - params.drift.x, 2);
            y_ave = mean(params.fiducials.coords(pk_ids, :, 2) - params.drift.y, 2);
            
            %whos
        
            figure(h_palmpanel); hold on;
            
            % delete the existing handl
            if isfield(handles, 'fpicked')
                delete(handles.fpicked);
            end
            
            handles.fpicked = plot(x_ave, y_ave, 's', 'LineWidth', 2, 'MarkerSize', 11, ...
                'MarkerEdgeColor', 'g');
        else
            if isfield(handles, 'fpicked')
                delete(handles.fpicked);
            end
        end
        
        % now draw the selected markers
        if ~isempty(fids)
            x_ave = mean(params.fiducials.coords(fids, :, 1) - params.drift.x, 2);
            y_ave = mean(params.fiducials.coords(fids, :, 2) - params.drift.y, 2);
            
            %whos
        
            figure(h_palmpanel); hold on;
            
            % delete the existing handl
            if isfield(handles, 'fselected')
                delete(handles.fselected);
            end
            
            handles.fselected = plot(x_ave, y_ave, 's', 'LineWidth', 2, 'MarkerSize', 7, ...
                'MarkerEdgeColor', 'm');
        else
            if isfield(handles, 'fselected')
                delete(handles.fselected);
            end
        end
    end
    %%%%%%%%%%%%%%%% end of mark_sumimage %%%%%%%%%%%%%%%%
    
    %%
    %%%%%%%%%%%%% function onfiducialclick %%%%%%%%%%%%%%%%
    function onfiducialclick(object, event)
    % this function handles clicks on the fiducial list
    % the two parameters object and event are:
    %   object: ths list itself
    %   event: the event with details.
    %          subfield .Source has information re: the click
    %          Source.Value is an array with all selected items
        switch event.EventName
            case 'Action'
                fids = event.Source.Value;
                
                % send the selections to plotfiducials function
                plotfiducials(fids);
                
                % check the selected items and update pick and unpick
                % buttons
                if isempty(fids)
                    dch.btnPick.Enable = 'off';
                    dch.btnUnpick.Enable = 'off';
                else
                    is_picked = 0;
                    f_picked = params.fiducials.picked;
                    
                    % if any picked ids belong to picked or not picked,
                    % then update the buttons tatus
                    for i = fids
                        if f_picked(i) == 1
                            is_picked = is_picked + 1;
                        end
                    end    
                    
                    if is_picked > 0
                        dch.btnUnpick.Enable = 'on';
                    else
                        dch.btnUnpick.Enable = 'off';
                    end

                    if is_picked < numel(fids) % some non-picked
                        dch.btnPick.Enable = 'on';
                    else
                        dch.btnPick.Enable = 'off';
                    end
                end
 
        end
        
        check_apply;
        
        % put control back to the list
        uicontrol(dch.lstFiducials);
    end
    %%%%%%%%%%%%%% end of onfiducialclick %%%%%%%%%%%%%%

    %%
    %%%%%%%%%%%%%%% function populate_list %%%%%%%%%%%%
    function populate_list
    % function to populate the fiduciary information
    
        if isstruct(params.fiducials)       % the new format 
            if isfield(params.fiducials, 'total')
                %disp('New fiducials format');
                if params.fiducials.total == 0
                    clear_fiducials;
                end
            else
                clear_fiducials;
            end
        else
            %disp('Old fiducials format');
            if isempty(params.fiducials)
                clear_fiducials;
            else 
                [n,~,c] = size(params.fiducials);
                    
                if c ~= 5   % not recongizable fiducials
                    clear_fiducials;
                else
                    % transfer the coords to the subfield
                    temp = params.fiducials;
                    params = rmfield(params, 'fiducials');
                    params.fiducials.total = n;
                    params.fiducials.picked = ones(n, 1);
                    params.fiducials.applied = 2;
                    % pre-defined fiducials. mark pids = 0 (cannot remove)
                    params.fiducials.pids = zeros(n, 1);
                    params.fiducials.coords = temp;
                    params.drift.x = zeros(1, params.frames);
                    params.drift.y = zeros(1, params.frames);
                end
            end
        end
        
        % now fiducials structure is populated, update the form(s)
        if params.fiducials.total == 0
            dch.lstFiducials.String = 'None';
            dch.lstFiducials.Enable = 'off';
        else
            n = params.fiducials.total;
            p = find(params.fiducials.picked == 1);
            lst_str = sprintf('%3i  ', 1:n);

            % add a '*' to the ones that are picked
            if isempty(p)
                update_DCstatus('No fiducials picked.');
            else
                for i = p
                    lst_str(5 * i) = '*';
                end
                %msg = sprintf("%d",p);
                %update_DCstatus(['Particles ' msg ' are picked as current fiducials.']);
            end
            dch.lstFiducials.String = cellstr(reshape(lst_str, 5, n)');
            dch.lstFiducials.Enable = 'on';
            dch.lstFiducials.Value = [];
            dch.btnPick.Enable = 'off';
            dch.btnUnpick.Enable = 'off';
        end
        
        update_MSD;
    end
    %%%%%%%%%%%%%%% end of populate_list %%%%%%%%%%%%
    
    %%
    %%%%%%%%%%%% function clear_fiducials %%%%%%%%%%%%%%%%
    function clear_fiducials
    % this function clears out all fiducials and reformats
    % the fiducials struct
       
        params.fiducials.total = 0;
        params.fiducials.picked = [];
        params.fiducials.applied = 0;
        params.fiducials.pids = [];
        params.fiducials.coords = [];
        
        params.drift.x = zeros(1, params.frames);
        params.drift.y = zeros(1, params.frames);
        
        update_DCstatus('No fiducials defined.');
        update_MSD;

    end
    %%%%%%%%%%%% end of clear_fiducials %%%%%%%%%%%%%%

    %%
    %%%%%%%%%%% function check_apply %%%%%%%%%%%%%%
    function check_apply
    % this function checks the 'applied' status of the fiducials
    % if the 'applied' field is 2, the fiducials can only be checked
    % and not modified
        if params.fiducials.applied == 2
            dch.btnFind.Enable = 'off';
            dch.btnPick.Enable = 'off';
            dch.btnUnpick.Enable = 'off';
            dch.btnApply.Enable = 'off';
            dch.btnUnapply.Enable = 'on';
            update_DCstatus('Fiducials were predefined in wfiread. Please Unapply before making any changes.');
        else
            dch.btnFind.Enable = 'on';

            if params.fiducials.applied == 1
                dch.btnApply.Enable = 'off';
                
                if params.is_sorted == 1
                    dcmsg = 'Current fiducials have been applied, and the coordinates have been re-sorted. Ready to render.';
                else
                    dcmsg = 'Current fiducials have been applied. Please sort the cor file again before rendering.';
                end
                update_DCstatus(dcmsg);
            else
                pk_ids = find(params.fiducials.picked == 1);
                
                if isempty(pk_ids)  % no fiducials picked - disable 'Apply'
                    dch.btnApply.Enable = 'off';
                    update_DCstatus('No Fiducials picked. Please pick fiducials before applying drift correction.');
                else
                    dch.btnApply.Enable = 'on';
                    update_DCstatus('Fiducials were changed but have not been applied.');
                end
            end
            
            % the 'Unapply' button depends on the params.drift status
            if isfield(params, 'drift')
                if any(params.drift.x) || any(params.drift.y)
                    % drift correction has been applied
                    dch.btnUnapply.Enable = 'on';
                else
                    dch.btnUnapply.Enable = 'off';
                end
            else
                dch.btnUnapply.Enable = 'on';
            end
        end
    end
    %%%%%%%%%%%% end of check_apply %%%%%%%%%%%%%
    
    %%
    %%%%%%%%%%% function update_MSD %%%%%%%%%%%%
    function update_MSD
    % function that calculates and updates the MSD among the picked
    % fiducials
        picked_ids = find(params.fiducials.picked == 1);
        
        if isempty(picked_ids)
            dch.edMSD.String = 'N/A';
        else
            % calculate the mean x and y positions of all fiducials
            x_picked = mean(params.fiducials.coords(picked_ids, :, 1), 1);
            y_picked = mean(params.fiducials.coords(picked_ids, :, 2), 1);
            
            % apply the corrections to all fiducials
            x_corr = params.fiducials.coords(picked_ids, :, 1) - x_picked;
            y_corr = params.fiducials.coords(picked_ids, :, 2) - y_picked;
            
            % calculate the standard deviations of all corrected trajs
            x_err = mean(std(x_corr, 0, 2));
            y_err = mean(std(y_corr, 0, 2));

            dch.edMSD.String = sprintf('(%.2f, %.2f)', x_err, y_err);
        end
    end
    %%%%%%%%%%%% end of update_MSD %%%%%%%%%%%%%
    
    %%
    %%%%%%%%%%% function update_DCstatus %%%%%%%%%%%%
    function update_DCstatus(status)
    % this function updates the status of the Drift Correction message bar.
        dch.DCstatus.String = status;
    end
    %%%%%%%%%%%% end of update_DCstatus %%%%%%%%%%%%%

end

