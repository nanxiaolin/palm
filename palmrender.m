function palmrender(object, event)
%
% palmrender: the palm image rendering function
% this functions take the .scf matrix field and generate a final PALM
% image using the desired rendering resolution
%
% by default, this function is called by system call back
% when object == 0 it is called internally by other functions
%   and when event = 1, it is to generate a fine (1 nm/pixel) PALM image for current view in a new window
%
% Update on 03/26/2016
%   1. added new functions to render frames within a specified range
%   2. added new functions to render live 'movies' by combining certain
%   number of frames.
%
% Update on 02/12/2020
%   1. Added the ability to render stable fiducary markers, including those
%   that do not qualify as full range fiducials (e.g. appearing in ~80% of
%   the frames). This is done by creating a multiplication matrix based on
%   the strength of the fiduciary.

	global h_palmpanel handles params;

	pixsize = str2num(get(handles.pixelsize, 'string'));
    show_landmark = get(handles.showlandmark, 'value');

	dispmessage('Analyzing particles and preparing for image rendering ...');
	pause(0.01);
	
	if object == 0	% called by renders to generate high resolution images of current view
		% get the current viewport
		[ind x0 y0 x1 y1] = getpointsinview();
		scf = params.scf(ind, :);
		%figure; plot(scf(:, 1), scf(:, 2), 'g.'); axis image;
		scf(:, 1) = scf(:, 1) - (x0 - 2 * params.feature_size) / params.palm_mag;
		scf(:, 2) = scf(:, 2) - (y0 - 2 * params.feature_size) / params.palm_mag;

		width  = (x1 - x0 + 1) / params.palm_mag;
		height = (y1 - y0 + 1) / params.palm_mag;

		if(width >=100 || height >=100)	% image will be too large
			ans = questdlg('Area of interest is over 100 raw pixels. It will take a long time to generate the final image. Continue?', 'Warning!');
			if strcmp(ans, 'No')
				dispmessage('User cancelled.');
				return;
			end
        end
		
		% if the FOV is too big, then use 2 or even 5 nm rendering
		palm_width  = width * pixsize;
		palm_height = height * pixsize;
		
		if palm_width * palm_height <= 1e9
			palm_pixelsize = 1;
		else
			if palm_width * palm_height <= 4e9
				palm_pixelsize = 2;
			else
				palm_pixelsize = 5;
			end
		end
		
		msg = sprintf('Fine rendering of a (%.1f um x %.1f um) region using a pixel size of %d nm ... ', palm_width/1000.0, palm_height/1000.0, palm_pixelsize);
		dispmessage(msg);
		disp(msg);
		pause(1.5);
				
        % render multiplication matrix: use default (1 for each particle)
        num_render = zeros(length(ind), 1);
        
        set(handles.highres, 'callback', @onstop, 'string', 'Stop');
	else
		scf = params.scf;
		width = params.width;
		height = params.height;
		palm_pixelsize = str2num(get(handles.renderpix, 'string'));	

		% render multiplication matrix: use default (1 for each particle)
        num_render = zeros(numel(scf(:, 1)), 1);
        
        set(handles.renderpalm, 'callback', @onstop, 'string', 'Stop');
    end
    
    %ind = find(num_render > 1)
    %num_render(ind)
    %msg = sprintf('A total of %d landmarks will be highlighted during rendering.', num_stbl_fds);
    %disp(msg);    
    
    % apply the frame number filter
    start_frame = str2num(get(handles.startframe, 'String'));
    end_frame = str2num(get(handles.endframe, 'String'));
    ind = find(scf(:, 4) >= start_frame);
    scf = scf(ind, :);
    num_render = num_render(ind);
    ind = find(scf(:, 4) <= end_frame);
    scf = scf(ind, :);
    num_render = num_render(ind);
    frames = end_frame - start_frame + 1;
	
    if show_landmark == 1 && object ~=0
	% added 02/12/2020 Xiaolin Nan
	% in order to highlight stable landmarks (fiducials - including those
	% do not quality as full range fiducials, create a multiplication
	% matrix to help determine how many times a particle should be
	% rendered. typically each sorted particle is rendered only once.
	% however, for those that can serve as stable markers they can be
	% rendered multiple times to help with subsequent registration.
       
        min_frames = 1000;     % min number of frames 
        min_fraction = 0.2;    % at least 10% of the total frames
		max_repeats = 50;	   % max # of times that a marker should be rendered
        
        if min_frames < min_fraction * params.frames
            min_frames = min_fraction * params.frames;
        else
            if min_frames > params.frames
                min_frames = params.frames;
            end
        end    
        
		% look for all potential fiducials that lasted 20% of frames and within stability of 
		% 0.2 pixels (x + y) relative to the picked fiducials.
		marker_scf = get_stablefds(min_frames, 0.2);
		
		%msg = sprintf("The markers are at (%i, %i).\n", marker_scf(:,1), marker_scf(:,2));
		%disp(msg);
			
		% highlight the markers that will be highlighed during rendering
		figure(h_palmpanel); hold on; 			
	
		if isfield(handles, 'fselected')
			delete(handles.fselected);
		end	
		
		if ~isempty(marker_scf)
			handles.fselected = plot(marker_scf(:, 1), marker_scf(:, 2), '+', 'LineWidth', 2, 'MarkerSize', 7, ...
                'MarkerEdgeColor', 'm');	
		
			% append the marker_scf to the main scf
			scf = [scf; marker_scf];
			marker_num_render = floor(max_repeats * marker_scf(:, 5) / params.frames);
			num_render = [num_render; marker_num_render];
		end
	end	
		
    particle_num = length(scf);
    if particle_num == 0
		dispmessage('Particles have not been sorted. Click SORT first');
		return;
    end		
	% create the final image matrix
	render_res = str2num(get(handles.renderres, 'string'));
	feature_size = ceil(render_res / palm_pixelsize);
    renderimg = gauss2d(0, 100, 2*feature_size, 2*feature_size, 0.5*feature_size, 4*feature_size+1, 4*feature_size+1);
    
    %make a thick square with a center cross image as landmarks
    lm_renderimg = 0.1* renderimg;
    lm_renderimg(2*feature_size+1, :) = 100;
    lm_renderimg(:, 2*feature_size+1) = 100;
    %lm_renderimg(1:2, :) = 100;
    %lm_renderimg(:, 1:2) = 100;
    %lm_renderimg(4*feature_size:4*feature_size+1, :)=100;
    %lm_renderimg(:, 4*feature_size:4*feature_size+1)=100;    
    
	palm_mag  = pixsize / palm_pixelsize;
	palm_xdim = ceil(palm_mag * width) + 4*feature_size + 1;
	palm_ydim = ceil(palm_mag * height) + 4*feature_size + 1;
    
    if params.moviemode == 0        % render a single, summed image
        palm_img  = zeros(palm_ydim, palm_xdim);
        palm_frames = 1;
    else
        movie_combine_frames = str2num(get(handles.movieframe, 'String'));
        palm_frames = floor(2 * frames / movie_combine_frames);
        palm_img = zeros(palm_ydim, palm_xdim, palm_frames);
        
        cumulative_mode = get(handles.timecumulative, 'value');
    end

    stop = 0;
	msg = sprintf('Rendering particles. Please wait ...');
	dispmessage(msg);
	pause(0.001);	
    

    % start to render the particles
	for i = 1 : particle_num
		if mod(i, 2000) == 0	|| i == particle_num || i == 1	
			dispmessage(sprintf('Rendering particle %d', i));
            pause(0.01);
        end
        
        if stop == 1
           stoprender;
           return;
        end

		x   = round(palm_mag * scf(i, 1)) + 2*feature_size;
		y   = round(palm_mag * scf(i, 2)) + 2*feature_size;

		ys = y-2*feature_size;		ye = y+2*feature_size;
		xs = x-2*feature_size; 		xe = x+2*feature_size;

        % for each particle within the range, put it in all the frames that it belongs to
        if(xs > 0 && ys > 0 && ye < palm_ydim && xe < palm_xdim)
            switch params.moviemode
                case 0
					% for locations overlapping with fiducial markers, decrease the original brightness
                    palm_img(ys : ye, xs : xe) = palm_img(ys : ye, xs : xe)/(num_render(i)+1) + renderimg + lm_renderimg* num_render(i);
                case 1
                    p_start = floor(2* (scf(i, 4) - start_frame + 1)/movie_combine_frames) + 1;
                    
                    if p_start < 1
                        p_start = 1;
                    end

                    if cumulative_mode == 0
                        p_end = floor(2* (scf(i, 4) + scf(i, 5) - start_frame + 1)/movie_combine_frames) + 1;
                    else
                        p_end = palm_frames;
                    end

                    if p_end > palm_frames
                        p_end = palm_frames;
                    end
                    
                    for j = p_start : p_end
                        palm_img(ys : ye, xs : xe, j) = ...
									palm_img(ys : ye, xs : xe, j)/(num_render(i)+1) + renderimg + lm_renderimg* num_render(i);
                    end
            end
        end
        % pause();   
    end
    
    dispmessage(sprintf('Rendered %d particles in %d frame(s).', particle_num, palm_frames));
    pause(0.01);
    
	rendersize = 800;


	if object ~= 0 % render whole PALM image only
		fig_mag = min(rendersize/palm_ydim, rendersize/palm_xdim) * 100.0;
		params.palm_img = palm_img;
        params.fig_mag = fig_mag;
		params.palm_pixelsize = palm_pixelsize;
		params.palm_mag = palm_mag;
		params.feature_size = feature_size;
		psf_size = ceil(300/palm_pixelsize);		
		params.psf = gauss2d(0, 10, psf_size, psf_size, 150/palm_pixelsize, 2*psf_size+1, 2*psf_size+1);
        params.palm_frames = palm_frames;
		% show the image
	
		set(handles.autoscale, 'enable', 'on');
		autoscale = get(handles.autoscale, 'value');
		if autoscale == 1
			[disp_low disp_high] = autoscale2d(palm_img(:, :, 1));
			%disp_high = 0.2* max(max(palm_img))
			set(handles.displow, 'string', num2str(disp_low, '%.1f'));
			set(handles.disphigh, 'string', num2str(disp_high, '%.1f'));
		else
			disp_low = str2num(get(handles.displow, 'string'));
			disp_high = str2num(get(handles.disphigh, 'string'));
		end	
		
		% see if there's a window open
		if(handles.palmfig == -1)
			handles.palmfig = figure; 
			
		end

		figure(handles.palmfig); 
        
        switch params.moviemode
            case 0      % regular sum image mode
                hold off; clf; imshow(palm_img, [disp_low disp_high], 'InitialMagnification', fig_mag);
                axis on; axis image; colormap(gca, 'hot');
                titlemsg = sprintf('Rendered at %d nm/pixel', params.palm_pixelsize);
                title(titlemsg);
                filen = params.filename(1:length(params.filename)-4);
                wintitle = sprintf('PALM Image of %s', filen);
                set(handles.palmfig, 'Position', [200 200 rendersize rendersize], 'CloseRequestFcn', @onfigpalmclosed);
                set(handles.palmfig, 'name', wintitle, 'NumberTitle', 'off', 'Toolbar', 'Figure');
                
            case 1      % time series mode
                hold off; clf; imshow(palm_img(:, :, 1), [disp_low disp_high], 'InitialMagnification', fig_mag);
                axis on; axis image; colormap(gca, 'hot');
                titlemsg = sprintf('Rendered at %d nm/pixel (frame 1 of %d)', params.palm_pixelsize, params.palm_frames);
                title(titlemsg);
                filen = params.filename(1:length(params.filename)-4);
                wintitle = sprintf('PALM Image of %s', filen);
                
                % adjust the positions of the window and the axis
                win_pos = get(gcf, 'position');     ax_pos = get(gca, 'position'); 
                set(handles.palmfig, 'Position', [win_pos(1) win_pos(2) win_pos(3) win_pos(4)*1.05], 'CloseRequestFcn', @onfigpalmclosed);
                set(handles.palmfig, 'name', wintitle, 'NumberTitle', 'off','Toolbar', 'Figure', 'Resize', 'off');
                
                set(gca,'ActivePositionProperty', 'position');
                set(gca, 'Position', [ax_pos(1) ax_pos(2)+ax_pos(4)*0.025 ax_pos(3) ax_pos(4)]);

                % now draw the slider and set the slider response function
                handles.palmslider = uicontrol('style', 'slider', 'Min', 1, 'Max', params.palm_frames, 'value', 1);
                pos = get(handles.palmfig, 'Position'); 

                slider_hpos = pos(3)*3/8 + 50; slider_vpos = 0.03 * rendersize;
                slider_width = pos(3)/4; slider_height = 20;
                set(handles.palmslider, 'Position', [slider_hpos, slider_vpos, slider_width, slider_height]);
                step = 1/(params.palm_frames-1);
                set(handles.palmslider, 'SliderStep', [step, 2*step], 'callback', @onpalmslider);
                
                % draw a buttom for playing the movie
                handles.palmplay = uicontrol('style', 'pushbutton', 'position', [slider_hpos - 60, slider_vpos, 50, slider_height], ...
                    'String', 'Play', 'callback', @onpalmplay, 'FontSize', 9);
                
                % do not delete this following line - for unclear reasons
                % this will keep the current axis constant in redrawing.
                hold on;
        end

		params.fig_mag = fig_mag;
		params.palm_xdim = palm_xdim;
		params.palm_ydim = palm_ydim;
        set(handles.renderpalm, 'String', 'Render', 'callback', @palmrender);
        
		% enable the 'low res' button
		set(handles.lowres, 'enable', 'on');
		set(handles.highres, 'enable', 'on');
		set(handles.cluster, 'enable', 'on', 'callback', @clusteranalysis);
		
    else  % for rendering high resolution images
		fig_mag = min(rendersize/(palm_ydim - 4*feature_size), rendersize/(palm_xdim - 4*feature_size)) * 100.0;
		%[disp_low disp_high] = autoscale2d(palm_img);
		autoscale = get(handles.autoscale, 'value');
        params.palm_img_highres = palm_img;
        params.highres_frames = palm_frames;
        
		if autoscale == 1
			[disp_low, disp_high] = autoscale2d(palm_img(:, :, 1));
			%disp_high = 0.2* max(max(palm_img))
			% display high and low values to 0.1 precision
			set(handles.displow, 'string', num2str(disp_low, '%.1f'));	
			set(handles.disphigh, 'string', num2str(disp_high, '%.1f'));
		else
			disp_low = str2num(get(handles.displow, 'string'));
			disp_high = str2num(get(handles.disphigh, 'string'));
		end	
		
		if handles.figfine == -1
			h = figure; 
			set(h, 'Position', get(handles.palmfig, 'Position'));
			handles.figfine = h;
		else
			h = handles.figfine;	
		end
		
		figure(h); set(h, 'CloseRequestFcn', @onfigfineclosed); 
        
        switch params.moviemode
            case 0
                show_y = 2*feature_size : palm_ydim - 2*feature_size;
                show_x = 2*feature_size : palm_xdim - 2*feature_size;
                hold off; clf; imshow(palm_img(show_y, show_x), [disp_low disp_high], 'InitialMagnification', fig_mag);
                axis on; axis image; colormap(gca, 'hot');
                xlabel('X (pixel)');	ylabel('Y (pixel)');
                titlemsg = sprintf('PALM Image Rendered at %d nm/pixel. Viewport = (%d, %d) - (%d, %d)', palm_pixelsize, x0, x1, y0, y1);
                title(titlemsg);
                
                filen = params.filename(1:length(params.filename)-4);
                wintitle = sprintf('PALM Image of %s', filen);
                set(handles.figfine, 'name', wintitle, 'NumberTitle', 'off', 'Toolbar', 'Figure');
                
            case 1
                show_y = 2*feature_size : palm_ydim - 2*feature_size;
                show_x = 2*feature_size : palm_xdim - 2*feature_size;
                hold off; clf; imshow(palm_img(show_y, show_x, 1), [disp_low disp_high], 'InitialMagnification', fig_mag);
                axis on; axis image; colormap(gca, 'hot');
                
                titlemsg = sprintf('PALM Image Rendered at %d nm/pixel (frame 1 of %d). Viewport = (%d, %d) - (%d, %d)', palm_pixelsize, params.palm_frames, x0, x1, y0, y1);
                title(titlemsg);
                
                filen = params.filename(1:length(params.filename)-4);
                wintitle = sprintf('PALM Image of %s', filen);
                
                % adjust the positions of the window and the axis
                win_pos = get(handles.figfine, 'position');     ax_pos = get(gca, 'position');    
                set(handles.figfine, 'Position', [win_pos(1) win_pos(2) win_pos(3) win_pos(4)*1.05], 'CloseRequestFcn', @onfigfineclosed);
                set(handles.figfine, 'name', wintitle, 'NumberTitle', 'off','Toolbar', 'Figure', 'Resize', 'off');
                
                set(gca,'ActivePositionProperty', 'position');
                set(gca, 'Position', [ax_pos(1) ax_pos(2)+ax_pos(4)*0.025 ax_pos(3) ax_pos(4)]);
                
                %set(handles.figfine, 'Position', [200 200 rendersize rendersize*1.05]);
                %set(gcf, 'name', wintitle, 'NumberTitle', 'off', 'Toolbar', 'Figure', 'resize', 'off');
                
                % now draw the slider and set the slider response function
                handles.palmfineslider = uicontrol('style', 'slider', 'Min', 1, 'Max', params.highres_frames, 'value', 1);
                pos = get(handles.figfine, 'Position');
                xlabel('X (pixel)');	ylabel('Y (pixel)');
                slider_hpos = pos(3)*3/8; slider_vpos = 0.03 * rendersize;
                slider_width = pos(3)/4; slider_height = 20;
                set(handles.palmfineslider, 'Position', [slider_hpos, slider_vpos, slider_width, slider_height]);
                step = 1/(params.highres_frames-1);
                set(handles.palmfineslider, 'SliderStep', [step, 2*step], 'callback', @onpalmfineslider);
                
                % draw a buttom for playing the movie
                handles.palmfineplay = uicontrol('style', 'pushbutton', 'position', [slider_hpos - 60, slider_vpos, 50, slider_height], ...
                    'String', 'Play', 'callback', @onpalmfineplay, 'FontSize', 9);
                
                % do not delete this following line - for unclear reasons
                % this will keep the current axis constant in redrawing.
                hold on;
        end
        
		set(handles.highres, 'String', 'Fine', 'callback', @palmhighres);
		% record the current view information in the 'userdata' field of FineFig
		fv_userdata = get(h, 'userdata');
		fv_userdata.ind = ind;
		fv_userdata.x0 = x0;
		fv_userdata.y0 = y0;
		fv_userdata.x1 = x1;
		fv_userdata.y1 = y1;
		
		% initialize the cur_point handle for pointtrack to use
		fv_userdata.h_curpoint = -1;
		
		set(h, 'userdata', fv_userdata);
		
		% activate buttons for viewport analysis
		set(handles.pointtrack, 'enable', 'on', 'callback', @pointtrack);
    end	

    set(handles.palmexport, 'enable', 'on', 'callback', @palmexport);
    
	msg = sprintf('Rendering particles. Please wait ... done.');
	dispmessage(msg);
	param.palm_img = [];
	pause(0.01);
    
    function onstop(object, event)
        stop = 1;
    end
    
    function stoprender
        % function that handles interrupted rendering
        if object ~= 0
            set(handles.renderpalm, 'String', 'Render', 'callback', @palmrender);
        else
            set(handles.highres, 'String', 'Fine', 'callback', @palmhighres);
        end
        
        dispmessage('Rendering interrupted by user. Exiting ...');
    end
	
	function fd_coords = get_stablefds(min_frames, max_rms)
	% this function returns the positions of all the markers and returns
	% a marker_scf matrix that can be appended to the main scf.
	% 
	% this marker list contains two parts: those from the scf and those
	% in the .fiducials and satisfy the criteria:
	% 	1. for particles in the scf, min_fraction and max_rms
	%	2. for those in .fiducials, max_rms
	
		% check the scf list first
		
		idx = find(params.scf(:, 5) >= min_frames);
    
		if ~isempty(idx)
			fd_coords = params.scf(idx, :);	
			
			idx2 = find(sqrt(fd_coords(:, 6) .^2 + fd_coords(:, 7) .^2) < max_rms * pixsize);
			fd_coords = fd_coords(idx2, :);
		else
			fd_coords = [];
		end	
		
		% now examine the .fiducials list (only if the fiducials have been applied)
		if params.fiducials.applied == 1
			if isfield(params, 'drift')
				drift_x = params.drift.x;
				drift_y = params.drift.y;
			else
				drift_x = 0;
				drift_y = 0;
			end	
		
			% check for the std_x and std_y for each fiducial candidate
			for i = 1 : params.fiducials.total
				x = params.fiducials.coords(i, :, 1) - drift_x;
				y = params.fiducials.coords(i, :, 2) - drift_y;
				
				fd_rms = sqrt(std(x)^2 + std(y)^2);
				
				if fd_rms < max_rms
					temp_coords = zeros(1, 7);
					temp_coords(1) = mean(x);				% x_ave
					temp_coords(2) = mean(y);				% y_ave
					temp_coords(3) = 65535;					% sum intensity
					temp_coords(4) = 1;						% first frame
					temp_coords(5) = params.frames;			% number of frames
					temp_coords(6) = std(x);				% rms_x
					temp_coords(7) = std(y);				% rms_y
					fd_coords = [fd_coords; temp_coords];
				end
			end
		end
		
		% make sure that the same points are not picked twice.
		[num_fds, ~]=size(fd_coords);
		is_good = ones(1, num_fds);
		
		if num_fds > 2
			for i = 1 : num_fds - 1
				for j = i + 1: num_fds
					dist_fds = sqrt((fd_coords(i, 1) - fd_coords(j, 1))^2 + (fd_coords(i, 2) - fd_coords(j, 2))^2);
					
					% when two candidate fds are too close, use one from the larger index (e.g. the one from the fiducials list
					if dist_fds < 1
						is_good(i) = 0;
					end
				end
			end
		end
		
		fd_coords = fd_coords(is_good == 1, :);
	end
        
end


