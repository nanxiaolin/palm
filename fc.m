function [ptid cn] = fc(dim, x, y, k, epsilon, factor, showplot)
% fc = find clusters
%
% Function that assigns an array of points (x, y) into clusters
%   using an extended dbscan algorithm
% Usage:
%   [ptid cn] = fc(dim, x, y, k, epsilon, factor, showplot)
%   ptid: cluster ids assigned to each point (-1 = scattered points);
%   (x, y): point array
%   k: number of points considered as a cluster
%   showplot: show a plot (1) and a bar graph (2) or not at all (0)
%
% Important change on 02/28/2012
%   changed cn from '# of clusters' to '# of particles in clusters'
%   i.e. cn = cn .* sizes;
%
% Xiaolin Nan, UC Berkeley and Lawrence Berkeley National Lab, 2010.


% First step, calculates particle density

	if(dim == 0)  % if dim value is given, then calculate it
		dim_x = max(x) - min(x);
		dim_y = max(y) - min(y);
	else
		dim_x = dim;
		dim_y = dim;
	end

	if(epsilon == 0)	% when no epsilon parameter is provided, use simulations to calculate one
		pd = length(x) / (dim_x * dim_y);
		
		% number of particles used in a 10*10 pixels area for simulations
		np_sim = ceil(10000 * pd);		
	
		ds = zeros(np_sim * 100, 1);
	
		if(k < 2)
			k = 2;
		end
	
		% second step, run 100 simulations on randomly distributed particles
		nc = 100;
		for i = 1 : 100
			[sx sy] = simcluster(100, np_sim, nc, 5, []);
		
			for j = 1 : np_sim
				x0 = sx(j);		y0 = sy(j);
				d = dist(x0, y0, sx, sy);
			
				% sort the distance matrix
				d = sort(d);
			
				% take the (k-1)th smallest distance (d(1) always is 0 so use d(k) instead of d(k-1)
				ds((i-1)*np_sim + j) = d(k);
			end
		end
	
		% calculate the distance threshold for determining clusters
		epsilon = mean(ds)*factor;
		%std(ds);
	end
	
	% assign clusters to particles
	r = [x y];
	[class type] = dbscan(r, k-1, epsilon);
	
	% assort the cluster assignments
	ptid = zeros(length(x), 1);
	maxc = max(class);
	cid = 0;
	nps = 0;
	
	for i = 1 : maxc
		ids = find(class == i);
		if(type(ids(1)) == -1)	% outlier
			ptid(ids) = 0;
		else
			cid = cid + 1;
			nps = nps + length(ids);
			ptid(ids) = cid;
		end
	end

	% show a plot
	if(showplot >= 1)
		mesg = sprintf('Total %d clusters were found. \n%d out of %d particles in clusters.\nAverage cluster size: %.1f', ...
						cid, nps, length(x), nps/cid);
		disp(mesg);

		figure; plot(x, y, 'k+', 'MarkerSize', 8, 'LineWidth', 2); 
		grid on; box on; axis equal;
		
		if(dim == 0)
			axis tight;
		else
			xlim([0 dim]); ylim([0 dim]);
		end

		xlabel('x (pixel)'); ylabel('y (pixel)');
	end
	
	cs = zeros(cid, 1);
	
	colors = ['r' 'g' 'm' 'b' 'c' 'y'];
	for i = 1 : cid
		ids = find(ptid == i);
		cs(i) = numel(ids);
		if(showplot >= 1)
			hold on; plot(x(ids), y(ids), [colors(mod(i, 6)+1) 'o'], 'MarkerSize', 10, 'LineWidth', 2);
		end
	end	
	
	cn = hist(cs, 1:12);	
	sizes = 1 : 12;
	cn = cn .* sizes;
	cn(1) = numel(find(ptid == 0)); 		% scattered particles (i.e, cluster size = 1)
	
	% also show a cluster size histogram
	if(showplot > 1)
		figure; bar(1:10, cn(1:10));
		grid on; box on;
		xlim([0.5 10.5]);
		xlabel('Cluster Size (# pts)'); ylabel('# Clusters');
	end			
