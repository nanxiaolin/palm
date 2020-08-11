function [x0, y0] = simcluster(dim, np, nc, sc, nd, showfig) 
%% 
% SimCluster simulates a clustered distribution of particles
% [x0, y0] = simcluster(dim, np, nc, pc, sc, nd) 
% Parameters:
%   dim: size of the area - always square in this simulation
%   np: number of particles in the area
%   nc: number of clusters in the area
%   pc: particles per cluster (on average)
%   sc: size of clusters
%   nd: noise in particle positiond (
%
% 10/06/2010: added implementation for noise (or localization precision) data
%   nd: a distribution of noise of all particles.
%   nd should be a n x 2 array
%      first column:  localization noise with the same unit used by 'dim'
%      second column: relative probability
% Also changed the cx, cy calculationd so the core cluster size (without noise)
%   is always fixed at sc.
%
% 02/06/2012: added implementation for multiple cluster sizes
% [x0, y0] = simcluster(dim, np, nc, sc, nd) 
%   by using nc to describe the cluster size distribution; nc is now a vector
%   now np = total number of particles
%   nc = number of clusters (relative; size = 1, 2, 3, 4, ...)
%   pc = cluster sizes (this one is omitted in the new function as nc always corespond to 1,2,3,4...)
%   sc = diameter of clusters (in nm)
%   nd = noise distribution (spatial precision in nm)

% see if the vector nc is appropriate
	[r c] = size(nc);
	if(r ~= 1)
		disp('Vector NC should be Nx1 in dimension');
		return
	end
	
	if nargin == 5
		showfig = 0;
	end

%% step 1: generate a random list of particles as seeds
	max_cluster = c;		% number of different cluster sizes
	pc = zeros(max_cluster, 1);
	nc = nc ./ sum(nc);		% normalize the nc vector
	anp = zeros(max_cluster + 1, 1);			% anp = accumulative number of particles
	for i = 1: max_cluster
		pc(i) = ceil(np * nc(i) / i);	 % number of clusters in each size
		
	    anp(i+1) = anp(i) + pc(i) * i;
	end
	
	rnp = anp(max_cluster + 1);				% real number of particles
	num_seeds = sum(pc);
	x0 = zeros(rnp, 1);
	y0 = zeros(rnp, 1);

	% generate seeds
	seed_x = rand(num_seeds, 1) * dim;
	seed_y = rand(num_seeds, 1) * dim;
	
	% assign the seed coordinates to the [x0, y0] matrix
	seed_pos = 1;
	for i = 1 : max_cluster
		for j = 1 : pc(i)
			pos = anp(i) + (j-1)*i + 1;
			x0(pos : pos + i - 1) = seed_x(seed_pos);
			y0(pos : pos + i - 1) = seed_y(seed_pos);
			seed_pos = seed_pos + 1;
		end
	end
	%colors = [r g b k m];

	%whos
	%pause();
%% now the matrices x0, y0 are populated with proper seed positions

%% step 2: use a random list of nc particles as seeds and generate surrounding particles
	% apply this only to 

	% cx, cy are the offset matrices relative to the seed particles
	cx = sc * randn(rnp, 1) / (2 * 1.414);		
	cy = sc * randn(rnp, 1) / (2 * 1.414);		
	%temp = rand(rnp, 1) - 0.5;
	%sy = round(abs(temp) ./ temp);			% sign +/- for sy
	%cy = sqrt(0.25 * sc^2 - cx.^2)
	%cy = cy .* sy;
	
	% add the offsets to the original [x0, y0]
	x0 = x0 + cx;
	y0 = y0 + cy;
	
	if showfig == 1
		figure(1); hold on; plot(x0, y0, 'g.', 'MarkerSize', 6); axis equal; axis tight; grid on; box on;
	end
	
	if isempty(nd)
		return
	end
	
%% now add the noise part.
	% first, generate a noise array of rnp x 1 in size
	noise_x = zeros(rnp, 1);		
	noise_y = zeros(rnp, 1);
	
	% adjust the noise amplitude according to the nd distribution
	amps  = nd(:, 1);			% noise amplitude
	probs = nd(:, 2);			% noise probability
	probs = probs ./ sum(probs);
	bins  = length(amps);		% number of noise histogram bins
	bin_width = amps(2) - amps(1);
	
	pos_start = 1;
	for i = 1 : bins
		pos_end = round(sum(probs(1:i)) * rnp);		% last particle with the current amplitude
		
		if pos_end > rnp
			pos_end = rnp;
		end

		noise_x(pos_start : pos_end) = (amps(i) * randn(pos_end - pos_start + 1, 1)) * 1.15 / (1.414);
		noise_y(pos_start : pos_end) = (amps(i) * randn(pos_end - pos_start + 1, 1)) * 1.15 / (1.414);
			
		pos_start = pos_end + 1;
		
		if pos_start > rnp
			break;
		end
	end
	
	%noise = sqrt(noise_x.^2 + noise_y.^2);
	%hist(noise, 20);	

	order = randperm(rnp);
	x0 = x0 + noise_x(order);
	y0 = y0 + noise_y(order);
	
	
	% correct coords for particles outside boundary
	% remember not to set the offset too small. It will cause trouble
	% for the ripley k calculation (boundary correction)
	x0(find(x0<=1)) = 1;
	x0(find(x0>=dim-1)) = dim-1;
	y0(find(y0<=1)) = 1;
	y0(find(y0>=dim-1)) = dim-1;

	%hold on; plot(x0, y0, 'r.'); grid on; box on; axis equal; axis tight;
	%pause();

	if showfig == 1
		figure(1); hold on; plot(x0, y0, 'r.','MarkerSize', 6); axis tight; grid on; box on;
		figure(1); plot(seed_x, seed_y, 'b+', 'MarkerSize', 8); grid on; axis equal; axis tight;
		xlabel('X'); ylabel('Y'); axis tight; grid on; box on;
	end
end
