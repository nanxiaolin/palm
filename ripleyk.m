function rpc = ripleyk(x, y, width, height, step, msteps, nsims)
	% now start to caculate the K-function
    np = length(x);
    rs = zeros(nsims, msteps+1);
	
	rpc = kripley(x, y, width, height, step, msteps);

	% make 100 simulations of the particle density and choose the 99% CI index value
	% dispmessage('Running simulations on random particle sets ...');
	% pause(0.01);
	
    parfor i=1:nsims
		x = rand(np, 1) * width;
		y = rand(np, 1) * height;
	
		temp = kripley(x, y, width, height, step, msteps);
		rs(i, :) = temp;
	end

	% get the 99 percentile maximum of rs
	rps = mean(rs) + 3 * std(rs) / sqrt(nsims);
    rpc = rpc - rps';
	%figure; plot(rps, '-'); axis tight; 
	%hold on; plot(rpc, 'g-'); axis tight; ylim([-2 10]); grid on;
	%
	%for i = 2 : msteps + 1
	%	if(rps(i) ~= 0)
	%		rpc(i) = rpc(i) / rps(i);
	%	else
	%		rpc(i) = rpc(i - 1);
	%	end
	%end
	%hold on; plot(rpc, 'r-');
end
