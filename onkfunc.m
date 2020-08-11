function onkfunc(object, event)
% 
% onkfunc: calculate K-function on current viewport
%
% on 11/30/2011: assign a results.ktest structure to contain the k-test results for future convenience
% the structure elements are,
%   results.ktests.last = last k curve; (currently using temp)
%   results.ktests.last_param = params of the last k_curve;
%   results.ktests.rpcs = individual k curves in the pool; (currently using ktests itself
%   results.ktests.num  = number of pooled results
%   results.ktests.step = steps; (currently all at 0:1:200)
%   results.ktests.param = parameter array of the tested area
%   the param structure:
%       param.source = source file name
%       param.area = coordinates of the area tested
%       param.density = particle density of the area tested
%       param.coords = coordinates of all particles tested
%       param.nd = noise distribution of the particles (from full image)
% 
% with all the parameters it is possible to re-analyze the data without going back to the original file
% it is also possible to recall the original file for further analysis
% this is to facilitate sorting and organization of the data
% 
% when saving the results, make sure that do not save it as part of the 'results' structure
% but to transfer it to a temp substructure before saving it. This is to avoid problems when
% reloading the results into the memory 

	global h_palmpanel handles params results;
	
	[ind x0 y0 x1 y1] = getpointsinview;
	width = params.palm_pixelsize * (x1 - x0 + 1);
	height = params.palm_pixelsize * (y1 - y0 + 1);

	x = (params.scf(ind, 1) * params.palm_mag + 2*params.feature_size - x0 + 1)* params.palm_pixelsize;
	y = (params.scf(ind, 2) * params.palm_mag + 2*params.feature_size - y0 + 1)* params.palm_pixelsize;
	
	% make sure x, y are in range
	ind = find(x>0);
	x = x(ind); y = y(ind);
	ind = find(x<width);
	x = x(ind); y = y(ind);
	ind = find(y>0);
	x = x(ind); y = y(ind);
	ind = find(y<width);
	x = x(ind); y = y(ind);
	np = length(x);

	% always use 1 nm per pixel for calculation of k function
	%x = params.palm_pixelsize .* cords(:, 1);
	%y = params.palm_pixelsize .* cords(:, 2);
	%find(x<=0)
	%width  = params.palm_pixelsize * width;
	%height = params.palm_pixelsize * height;

	dispmessage('Calculating Ripley K function for particles in view ...');
	pause(0.01);
	step = 1.0;  % 1 nm per step
	msteps = 200;
	steps = 0 : 1: msteps;
	nsims = str2num(get(handles.cah.edNumSims, 'String'));
	rpc = ripleyk(x, y, width, height, step, msteps, nsims);

	%dispmessage('Running normalization simulations ... '); pause(0.1);	
	% calcualte the normalizing rpc values with 200 simulations assuming dimers
	pd = np * 1000000.0 / (width * height);
	
	% normalization
	[s r e] = simripley(2000, ceil(4*pd), [0 1], 6, getnd, 100, 0);
	max_norm = max(r);
	rpc = rpc ./ max_norm;
	
	% second step in normalization
	b = 53.3 * exp(-0.0644 * pd) + 42.3 * exp(-0.0039 * pd);
	a = 100 - b;
	
	rpc = (a * rpc + b * rpc.^2)/100.0;
	
	% afte these normalization steps, rpc is now the fraction of particles in dimers
	
	%whos
	dispmessage('Running normalization simulations ... Done');
	pause(0.1);
    h = figure('Visible', 'off');
	pos = get(h, 'Position');
	pos(3) = 560;	pos(4) = 340;
	plot(steps, rpc, '-', 'LineWidth', 2); axis tight; grid on;
	%hold on; plot(steps, rpc2, 'g-');
	xlim([-0.25 msteps]);
	ylim([-0.5 1.25]);
	y0 = zeros(length(steps), 1);
	hold on; plot(steps, y0, 'r--', 'LineWidth', 2);
	%if(max(rpc) < 2.4)
	%	ylim([min(rpc)-0.5 3]);
	%else
	%	ylim([min(rpc)-0.5 max(rpc)*1.25]);
	%end
	
	xlabel('r (nm)', 'FontSize', 14);
	ylabel('Normalized L(r) - r', 'FontSize', 14);
	%ylim([-0.25 1.1]);
	set(h, 'Color', [1 1 1], 'Position', pos, 'Name', 'Ripley K-Test', 'NumberTitle', 'off', 'Visible', 'on');
	
	titlemsg = sprintf('Particle density: %.1f per um2', pd);
	title(titlemsg);

	% save the test result in a temp array ktests.last
	results.ktests.last = rpc;
	if(results.ktests.num == 0)
		results.ktests.steps = steps;
	end

	% enable the pooling function
	set(handles.cah.btnpoolresultrpk, 'enable', 'on');
end


