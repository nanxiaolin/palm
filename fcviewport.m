function cn = fcviewport(epsilon, showstat)
%
% function fc_viewport finds clusters in current viewport as displayed in the palm window
%
% input arguments:
%
% Xiaolin Nan, UC Berkeley, 11/2011

	global params handles results h_palmpanel;

	% make sure there is a rendered palm image open
	if(handles.palmfig == -1)   % now open PALM image window
		msgbox('Render the image first.', 'Error');
		return;
	end

	[ind x0 y0 x1 y1] = getpointsinview;
	x = params.scf(ind, 1);
	y = params.scf(ind, 2);
	%[x0 y0 x1 y1]

	% find the clusters without drawing the plots
	[ptid cn] = fc(0, x, y, 2, epsilon, 0, 0);

	% draw a high res palm image of the current field of view
	palmrender(0, 1);
	xlabel('x (pixel)'); ylabel('y (pixel)');
	
	% draw the point markers
	cid = max(ptid);
	%cs = zeros(cid, 1);
	
	% change x, y coordinates to absolute x, y values - the same as used in high res PALM image
	x = (x * params.palm_mag - x0 + 2 * params.feature_size) * params.palm_pixelsize;
	y = (y * params.palm_mag - y0 + 2 * params.feature_size) * params.palm_pixelsize;
	
	colors = ['g' 'm' 'b' 'c' 'y' 'w'];
	for i = 1 : cid
		ids = find(ptid == i);
		%cs(i) = numel(ids);
		hold on; plot(x(ids), y(ids), [colors(mod(i, 6)+1) 'o'], 'MarkerSize', 12, 'LineWidth', 2);
	end	

	%cn = hist(cs, 1:12);
	%cn(1) = counts(1);
    
	% now fit the results
	x_size = max(x) - min(x) + 1;
	y_size = max(y) - min(y) + 1;		% x, y dimensions in nm
	dim = sqrt(x_size * y_size);
	%np = numel(x);
	nps = cn(1:10); % / sum(cn(1:10));
	np = sum(nps);
	%mesg = sprintf('Area to be fitted: %.0f nm with %.0f particles', dim, np);
	%disp(mesg);
    dispmessage('Fitting results with SAD ...');    
    pause(0.1);
    	
    msg_handle = findobj(h_palmpanel, 'tag', 'txtMessage');
	cn = fitfc(dim, np, nps, 20, getnd, 140, 2, epsilon, 0.01, 30, 1, msg_handle);
	cn = cn ./ sum(cn);
	
	if(showstat)
		% also show a cluster size histogram
		figure; bar(cn(1:10)); 
		grid on; %axis tight;
		xlim([0.2 10.8]); ylim([0 max(cn)*1.05]);
		xlabel('Cluster Size (# pts)'); ylabel('# Particles in Clusters');
	end
		
	results.fcv.last = cn(1:10);
	

