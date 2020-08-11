function [steps rpc err] = simripley(dim, np, nc, sc, nd, nsims, showplot)
%
% function [steps rpc] = simripley(dim, np, nc, pc, sc, nd, nsims)
%   This function simulates cluster settings assigned by dim, np, nc, pc,
%   sc, nd and calculates an average ripley's k curve
% Remember, the simulations always use 'nm' as the unit
%   typically the steps are from 0 - 200 nm at 2 nm steps
%
% 2012.02.07 - changed parameter list according to the most recent simcluster function
% Removed pc; nc is now a vector describes relative amounts of particles in clusters of
% a certain size (1, 2, 3, ...)

    %matlabpool open 4;
    
    steps = 0:1:200;
    rpc = zeros(nsims, 201);
    good_sim = zeros(nsims, 1);
    
    if showplot > 0
    	h = figure; hold on; grid on; box on;
    end
    
    for i = 1 : nsims    	
    	while(good_sim(i) == 0) 
	        [x y] = simcluster(dim, np, nc, sc, nd);
    	    temp = ripleyk(x,y,dim,dim,1,200,100);
        
        	if(isempty(find(isnan(temp) == 1)))
        		good_sim(i) = 1;
        	%else
        	%	disp('Bad Simulation Detected');
        	end
        end
        	
        rpc(i, :) = temp; %ripleyk(x,y,dim,dim,1,200,100);
        
        if showplot == 2 	% show each plot
       		hold on; plot(steps, rpc(i, :), 'g-'); axis tight; pause(0.1);
       	end 	
    end
    
    err = std(rpc) / sqrt(nsims);
    rpc = mean(rpc);

	if showplot
		hold on;
    	errorbar(steps, rpc, err, 'b'); 
    	hold on; plot(steps, rpc, 'b-', 'LineWidth', 3);
    	
    	xlim([0 160]);  	%ylim([-15 15]);
    	xlabel('r (nm)'); 	ylabel('L(r)-r');
    	grid on;
    	
    	% draw the y = 0 red line
    	hl = zeros(length(steps), 1);
    	hold on; plot(steps, hl, 'r--', 'LineWidth', 3);
    	
    	name = sprintf('Ripley-K Test of %d Simulations: %d particles', nsims, np);
    	set(h, 'numbertitle', 'off', 'name', name);
    
    	%plot(steps, rpc); box on; grid on; axis tight; 
    end	
    %matlabpool close;
end
