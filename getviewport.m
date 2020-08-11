function [x0, y0, x1, y1] = getviewport()
% function that acquires the current x and y limits so only the current view port is used
% to generate the low res image or other calculations
	global h_palmpanel params handles;

	palm_axes = get(handles.palmfig, 'CurrentAxes');
	xl = xlim(palm_axes);		yl = ylim(palm_axes);
	x0 = ceil(xl(1)); 			x1 = floor(xl(2));
	y0 = ceil(yl(1));			y1 = floor(yl(2));

	% make sure that all coords are in limit
	if x0 < 1
		x0 = 1;
	end
	
	if y0 < 1
		y0 = 1;
	end

	if x1 > params.palm_xdim
		x1 = params.palm_xdim;
	end
	
	if y1 > params.palm_ydim
		y1 = params.palm_ydim;
	end
end
