function [ind, x0, y0, x1, y1] = getpointsinview()
% function that the list of points that are in current view
%  1. calls getviewport to acquire the coordinate range
%  2. use the coordinate range to get the list of points
%
% returns:
%  ind - indices of points in the scf matrix
%  (x0, y0, x1, y1) - viewport coords in current palm_pixel units

	global h_palmpanel handles params;

	if(handles.palmfig == -1)   % now open PALM image window
		msgbox('Render the image first.', 'Error');
		return;
	end

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

	scf = params.scf * params.palm_mag + params.feature_size;
	
	% select out the area
	scf1 = scf(:, 1);
	ind  = find(scf1 > (x0 - 2*params.feature_size) & scf1 < (x1 + 2*params.feature_size));
	scf2 = scf(ind, 2);
	ind2 = find(scf2 > (y0 - 2*params.feature_size) & scf2 < (y1 + 2*params.feature_size));
	ind = ind(ind2);
end
