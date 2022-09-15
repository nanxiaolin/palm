function [x0, y0] = simcluster(dim, np, nc, pc, sc, nd) 
%% 
% SimCluster simulates a clustered distribution of particles in 
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


%% step 1: generate a random list of np particles
	x0 = rand(np, 1) * dim;
	y0 = rand(np, 1) * dim;

	%figure(1); plot(x0, y0, '.');
	%pause();

%% step 2: use a random list of nc particles as seeds and generate surrounding particles
	cx = rand(nc, pc) * sc; %  - sc/2.0     % 2.35 = 2*sigma;
	%cy = rand(nc, pc) * sc  - sc/2.0;
	cy = sqrt(sc ^2 - cx .^ 2); % - sc/2.0
	sx = rand(nc, 1) * (dim - sc) + sc/2;
	sy = rand(nc, 1) * (dim - sc) + sc/2;
	%sy = sc ^2 - sx .^ 2;
	
	%figure(1); hold on; plot(sx, sy, 'g.');
	%pause();

	% add the generated clsuter coords to the original x0, y0 coords
	for i = 1 : nc
		temp = cx(i, 1:pc) + sx(i);
		x0 = [x0;temp'];

		temp = cy(i, 1:pc) + sy(i);
		y0 = [y0;temp'];
	end

	%figure; plot(x0, y0, 'b.');

	% now the noise part.
	% first, generate a noise array (np + nc * pc)
	% normalize the probablity column of nd
	if length(nd) > 0
		num_particles = np + nc*pc;
		nd(:, 2) = round(nd(:, 2) / sum(nd(:, 2)) * num_particles);
	
		if num_particles < sum(nd(:, 2))
			num_particles = sum(nd(:, 2));
		end
		noise = rand(num_particles, 2);

		cur_pos = 1;
		noise_bars = length(nd(:, 1));
	
		for i = 1 : noise_bars
			pts = nd(i, 2);
		
			if pts == 0
				continue;
			end
		
			pos_range = cur_pos : cur_pos + pts - 1;
			noise(pos_range, 1) = noise(pos_range, 1) .* nd(i, 1);
			noise(pos_range, 2) = sqrt(nd(i, 1) ^ 2 - noise(pos_range, 1).^2);		% noise in y; x^2 + y^2 = bin value
		
			cur_pos = cur_pos + pts;
		end
	
		% shuffle noise terms
		num_particles = np + nc*pc;
		noise_final(1:num_particles, 1:2) = noise(randperm(num_particles), 1:2);
	
		% apply noise to coordinates
		x0 = x0 + noise_final(:, 1);
		y0 = y0 + noise_final(:, 2);
	end
	
	
	x0(find(x0<=0)) = 0.1;
	x0(find(x0>=dim)) = dim-0.1;
	y0(find(y0<=0)) = 0.1;
	y0(find(y0>=dim)) = dim-0.1;

	%hold on; plot(x0, y0, 'r.'); grid on; box on; axis equal; axis tight;
	%pause();

	%figure(1); plot(x0, y0, '.'); axis tight; grid on; box on;
	%xlabel('X'); ylabel('Y'); axis tight; grid on; box on;

end
