function showtrackpoint(object, event)
%
% showtrackpoint: shows tracking results of currently selected point
	
	global h_palmpanel handles params;	
	
	ah = get(handles.figfine, 'CurrentAxes');
	
	cp = get(ah, 'CurrentPoint');
	xl = xlim(ah);	yl = ylim(ah);

	xinit = cp(1, 1); yinit = cp(1, 2);

	if xinit < xl(1) || xinit > xl(2) || yinit < yl(1) || yinit > yl(2)
		%disp('Mouse click outside the image.');
		return;
	%else
		%disp(sprintf('Mouse click at point (%.0f, %.0f).', xinit, yinit));
    end

	% calculate if there is a particle that is within the range of *feature_size* of a particle in the field of view
	% remember that xinit and yinit are in units of 'nm'
	
	% first, get a list of 'points of interest' (or poi)
	cud = get(handles.figfine, 'userdata');
	xp = cud.x0 + (xinit - 1)/params.palm_pixelsize;		% xp, yp are in units of 'palm_pixelsize'
	yp = cud.y0 + (yinit - 1)/params.palm_pixelsize;
	
	%figure(handles.palmfig); hold on; plot(x, y, 'g+', 'MarkerSize', 10);	
	%figure(handles.figfine); hold on; plot(xinit, yinit, 'g+', 'MarkerSize', 10);

	x = (xp - 2 * params.feature_size) / params.palm_mag;
	y = (yp - 2 * params.feature_size) / params.palm_mag;	% now x, y are in units of original 'pixels'
	poi = params.scf(cud.ind, 1:2);	% 	only take the x and y coordinates
	dist = sqrt((poi(:, 1) - x) .^ 2 + (poi(:, 2) - y) .^2);
	[min_dist min_ind] = min(dist);
	
	%params.feature_size/params.palm_mag
	if(min_dist > (params.feature_size/params.palm_mag))
		return;
	end
	
	p_ind = cud.ind(min_ind);		% find out which particle it is in the scf list
	pixsize = params.palm_pixelsize * params.palm_mag;
	% now calculate its actual rendered position in the fine PALM image
	% use the same formula as used to calculate positions of particles in fine PALM image
	x_render = (params.scf(p_ind, 1) - (cud.x0 - 2 * params.feature_size) / params.palm_mag) * pixsize + 1;
	y_render = (params.scf(p_ind, 2) - (cud.y0 - 2 * params.feature_size) / params.palm_mag) * pixsize + 1;
	
	figure(handles.figfine); hold on; 
	if(cud.h_curpoint ~= -1)
		delete(cud.h_curpoint);
	end

	cud.h_curpoint = plot(x_render, y_render, 'go', 'MarkerSize', 16);
		
	% record cud (current user data)
	set(handles.figfine, 'userdata', cud);
	drawnow; pause(.02);
	
	% now that the point has been found, display the information in h_palmpanel
	raw_inds = find(params.sort_order == p_ind);
	frames = params.coords(raw_inds, 1);
	numframes = numel(frames);
	msg = sprintf('Particle = %d; Frames = ', p_ind);
	for i=1:numframes
		msg = sprintf('%s %d;', msg, frames(i));
	end
	dispmessage(msg);
	
	% draw the point positions out
	x = params.coords(raw_inds, 2);
	y = params.coords(raw_inds, 3);
	x_ave = params.scf(p_ind, 1);
	y_ave = params.scf(p_ind, 2);
	figure(h_palmpanel); hold off; plot(x, y, 'go', 'MarkerSize', 12);
	hold on; plot(x_ave, y_ave, 'r+', 'MarkerSize', 3);
	axis equal; axis tight; 
	xlim([min(x)-0.5 max(x)+0.5]);
	ylim([min(y)-0.5 max(y)+0.5]);
	grid on; title(sprintf('Particle %d', p_ind));
	
return
