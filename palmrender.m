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


	global h_palmpanel handles params;

	pixsize = str2num(get(handles.pixelsize, 'string'));

	if object == 0	% called by renders to generate high resolution images of current view
		% get the current viewport
		[ind x0 y0 x1 y1] = getpointsinview();
		scf = params.scf(ind, :);
		%figure; plot(scf(:, 1), scf(:, 2), 'g.'); axis image;
		scf(:, 1) = scf(:, 1) - (x0 - 2 * params.feature_size) / params.palm_mag;
		scf(:, 2) = scf(:, 2) - (y0 - 2 * params.feature_size) / params.palm_mag;

		palm_pixelsize = 1;
		width  = (x1 - x0 + 1) / params.palm_mag;
		height = (y1 - y0 + 1) / params.palm_mag;

		if(width >=100 || height >=100)	% image will be too large
			ans = questdlg('Area of interest is over 100 raw pixels. It will take a long time to generate the final image. Continue?', 'Warning!');
			if strcmp(ans, 'No')
				return;
			end
        end
        
        set(handles.highres, 'callback', @onstop, 'string', 'Stop');
	else
		scf = params.scf;
		width = params.width;
		height = params.height;
		palm_pixelsize = str2num(get(handles.renderpix, 'string'));	
        
        set(handles.renderpalm, 'callback', @onstop, 'string', 'Stop');
	end

	
    
    % apply the frame number filter
    start_frame = str2num(get(handles.startframe, 'String'));
    end_frame = str2num(get(handles.endframe, 'String'));
    ind = find(scf(:, 4) >= start_frame);
    scf = scf(ind, :);
    ind = find(scf(:, 4) <= end_frame);
    scf = scf(ind, :);
    frames = end_frame - start_frame + 1;
	
    particle_num = length(scf);
    if particle_num == 0
		dispmessage('Particles have not been sorted. Click SORT first');
		return;
    end		
	% create the final image matrix
	render_res = str2num(get(handles.renderres, 'string'));
	feature_size = ceil(render_res / palm_pixelsize);
    renderimg = gauss2d(0, 100, 2*feature_size, 2*feature_size, 0.5*feature_size, 4*feature_size+1, 4*feature_size+1);
	
	palm_mag  = pixsize / palm_pixelsize;
	palm_xdim = ceil(palm_mag * width) + 4*feature_size + 1;
	palm_ydim = ceil(palm_mag * height) + 4*feature_size + 1;
    
    if params.moviemode == 0        % render a single, summed image
        palm_img  = zeros(palm_ydim, palm_xdim);
        palm_frames = 1;
    else
        movie_combine_frames = str2num(get(handles.movieframe, 'String'));
        palm_frames = floor(frames / movie_combine_frames);
        palm_img = zeros(palm_ydim, palm_xdim, palm_frames);
        
        cumulative_mode = get(handles.timecumulative, 'value');
    end

    stop = 0;
	msg = sprintf('Rendering particles. Please wait ...');
	dispmessage(msg);
	pause(0.001);	

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
                    palm_img(ys : ye, xs : xe) = palm_img(ys : ye, xs : xe) + renderimg;
                case 1
                        p_start = floor((scf(i, 4) - start_frame + 1)/movie_combine_frames) + 1;
                    
                    if p_start < 1
                        p_start = 1;
                    end

                    if cumulative_mode == 0
                        p_end = floor((scf(i, 4) + scf(i, 5) - start_frame + 1)/movie_combine_frames) + 1;
                    else
                        p_end = palm_frames;
                    end

                    if p_end > palm_frames
                        p_end = palm_frames;
                    end
                    
                    for j = p_start : p_end
                        palm_img(ys : ye, xs : xe, j) = palm_img(ys : ye, xs : xe, j) + renderimg;
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
                axis on; axis image; colormap(hot);
                titlemsg = sprintf('Rendered at %d nm/pixel', params.palm_pixelsize);
                title(titlemsg);
                filen = params.filename(1:length(params.filename)-4);
                wintitle = sprintf('PALM Image of %s', filen);
                set(handles.palmfig, 'Position', [200 200 rendersize rendersize], 'CloseRequestFcn', @onfigpalmclosed);
                set(handles.palmfig, 'name', wintitle, 'NumberTitle', 'off', 'Toolbar', 'Figure');
                
            case 1      % time series mode
                hold off; clf; imshow(palm_img(:, :, 1), [disp_low disp_high], 'InitialMagnification', fig_mag);
                axis on; axis image; colormap(hot);
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
			[disp_low disp_high] = autoscale2d(palm_img(:, :, 1));
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
                axis on; axis image; colormap(hot);
                xlabel('X (nm)');	ylabel('Y (nm)');
                titlemsg = sprintf('PALM Image Rendered at 1 nm/pixel. Viewport = (%d, %d) - (%d, %d)', x0, x1, y0, y1);
                title(titlemsg);
                
                filen = params.filename(1:length(params.filename)-4);
                wintitle = sprintf('PALM Image of %s', filen);
                set(handles.figfine, 'name', wintitle, 'NumberTitle', 'off', 'Toolbar', 'Figure');
                
            case 1
                show_y = 2*feature_size : palm_ydim - 2*feature_size;
                show_x = 2*feature_size : palm_xdim - 2*feature_size;
                hold off; clf; imshow(palm_img(show_y, show_x, 1), [disp_low disp_high], 'InitialMagnification', fig_mag);
                axis on; axis image; colormap(hot);
                
                titlemsg = sprintf('PALM Image Rendered at 1 nm/pixel (frame 1 of %d). Viewport = (%d, %d) - (%d, %d)', params.palm_frames, x0, x1, y0, y1);
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
                xlabel('X (nm)');	ylabel('Y (nm)');
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
	pause(0.001);
    
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
        
        dispmessage('Rendering interrupted by user. Existing ...');
    end
        
end


