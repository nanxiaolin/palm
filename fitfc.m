function nc = fitfc(dim, np, nps, pd, nd, ps, k, sig, e, max_iter, show, msg_handle)
%
% function nc = fitfc(dim, np, nps, pd, nd, ps, k, sigma, e)
%  
% This function uses iterated simulations to find the actual cluster size distribution
% based on the output of fc.m and the other parameters.
%
% Input parameters are,
%   dim = dimension (nm)
%   np  = total number of particles
%   nps = cluster size distribution (the same as the nc array used for simcluster)
%   pd  = particle distance within a cluster
%   nd  = noise distribution (output of getnd(2))
%   ps  = pixel size (nm)
%   k   = minimum cluster size (# particles)
%   sig = maximum distance regarded as a cluster (pixels)
%   e   = minimum error (square root) before stopping 
%   max_iter = maximum number of iterations before stopping
%  show = show fitting process

% run the simfc simulation using the input nps as the starting point

  nps = np * nps/sum(nps);
  nc = nps;	% nc is used for simfc simulations
  se = 1;	% se = square root of errors
  iter = 1;	
  factor = 1;
  
  % check input arguments
  if nargin == 10		% both show and msg_handle  are omitted
  	show = 2;			% default: show everything
  	msg_handle = 0;		% default: console output
  elseif nargin == 11
  	msg_handle = 0;
  end
  
 
  % adjust parameters so we have enough number of particles to work with
  if np < 200
    factor = sqrt(400/np);
    
  	dim = factor * dim;
  	nc =  factor * factor * nc;
  	%e = e * factor * factor;
  	nps = nc;
  	np = 400;
  end

  nsims = 100;
  cor = 1;
	
  while (se > e && iter <= max_iter)

	if (se < 2.5 * e)
		nsims = 200;
		
		if (se < 1.5 * e)
			nsims = 400;
		end
	end
	
  	[nps2 err] = simfc(dim, np, nc, pd, nd, ps, k, sig, 1, nsims, 0);

  	se = sqrt(sum((nps - nps2).^2)) / np;
  	
  	if se > e
		nc = nc + cor * (nps - nps2);  	
	  	nc(find(nc<0)) = 0;
	  	nc = nc*np/sum(nc);
	end
  	
  	if show > 0
  		% compile the output string
  		mesg = sprintf('Iteration %d:\tError = %.3f\t  Result = [', iter, se);
  		for i = 1 : length(nc)
  			mesg = sprintf('%s %.0f', mesg, nc(i)/(factor*factor));
  		end
  		mesg = [mesg ' ]'];
  		
  		if msg_handle == 0	% console output
	  		disp(mesg);
	  	else
	  		set(msg_handle, 'string', mesg);
	  		pause(0.1);
	  	end
  	end
  	
  	iter = iter + 1;
  end
  
  if show ~= 2
  	return
  end
  
  nps = nps / (factor*factor);
  nps2 = nps2 / (factor*factor);
  nc = nc / (factor*factor);
  
  % compare the simulation results with the input
  figure;
  sizes = 1:length(nc);
  gbars = [nps;nps2;nc]';
  hold on; h = bar(sizes, gbars); grid on; box on;
  set(h(1), 'facecolor', [0 0 1], 'edgecolor', [0 0 0.5]);
  set(h(2), 'facecolor', [1 0 0], 'edgecolor', [0.5 0 0]);
  set(h(3), 'facecolor', [0 1 0], 'edgecolor', [0 0.5 0]);
  
  %hold on; bar(sizes, nps2, 'g', 'grouped'); grid on; box on;
  legend('Input from DBSCAN', 'DBSCAN on Simulated Clusters)', 'Actual Fitting Result');
  xlabel('Cluster Size'); ylabel('# Particles in Cluster');
  xlim([0 length(nc)+1]);
  
  
  
  
  
  
  
  
