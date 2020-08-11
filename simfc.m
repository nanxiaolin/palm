function [nps err] = simfc(dim, np, nc, pd, nd, ps, k, epi, factor, nsims, show)
%
% function that simulates clusters and use fc to detect the clusters
% parameters:
%   dim = dimension in number of nanometers
%   np = number of free particles
%   nc = number of clusters
%   cs = cluster size (# pts per cluster)
%   pd = particle distance within clusters
%   nd = noise distribution
%   ps = pixel size
%   k  = min # of pts regarded as a cluster in fc program
%   epi = min distance regarded as clusters
%   factor = factor to calculate epsilon in fc program
%   nsims = # of simulations

% create a csd (cluster size distribution) array to hold
% all the histogram results (cluster size 1:10)
%
% 2012.02.07 Changes made to the parameter list per the new simcluster
% function. removed cs and used nc as a vector

csd = zeros(nsims, 10);

%msg = sprintf('Running %d simulations ...', nsims);
%disp(msg);

parfor i = 1:nsims
	[x y] = simcluster(dim, np, nc, pd, nd);
	
	% correct for pixel size
	x = x./ps;
	y = y./ps;
	
	%if(i==1)  % show the first
	%	[ptid c] = fc(dim/ps, x, y, 2, epi, factor, 1);
	%else	
		[ptid c] = fc(dim/ps, x, y, 2, epi, factor, 0);
	%end
	
	%store the result
	csd(i, :) = c(1:10);
	%disp(['Running simulation ' num2str(i)]);
end

% calculate the average cluster size and error bar
csd_ave = mean(csd); %/ sum(mean(csd));
csd_err = std(csd) / sqrt(nsims);

% generate the figure;
% 02/28/2012 : csd_ave no longer needs to multiple .sizes as the fc function now
% output the total # of particles within clusters
% sizes = 1:10;
nps = csd_ave(1:10);
nps = np*nps/sum(nps);
err = csd_err(1:10); 

if show == 0
	return;
end

disp('Plotting results in bar graph ...');
h = figure; bar(1:10, nps, 'g'); grid on;
hold on; errorbar(1:10, nps, err, '.b');
xlim([0 11]); 
%y_min = 0;
y_max = np * 1.1 * max(nc) / sum(nc);
%ylim([0 1.05]);
xlabel('Cluster Size (# pts)');
ylabel('# Particles in Clusters');

%if(epi == 0) 
%	titlstr = sprintf('%d free pts + %d clusters * %d. factor = %.2f mean(ds)', np, nc, cs, factor);
%else
%    titlstr = sprintf('%d free pts + %d clusters * %d. epsilon = %.2f pixel', np, nc, cs, epi);
%end

% generate the text legends
%msg = sprintf(' Total # particles: %d\t ', np);
%text(5.7, y_max - 0.1, msg, 'FontName', 'Arial', 'FontSize', 12, 'BackgroundColor', 'w');
%msg = sprintf(' # free particles: %d\t\t', np);
%text(5.7, y_max - 0.15, msg, 'FontName', 'Arial', 'FontSize', 12, 'BackgroundColor', 'w');
%msg = sprintf(' # (%d-mers) expected: %d\t', cs, nc);
%text(5.7, y_max - 0.20, msg, 'FontName', 'Arial', 'FontSize', 12, 'BackgroundColor', 'w');
%max_cs = find(csd_ave == max(csd_ave));
%msg = sprintf(' # (%d-mers) detected: %.1f\t', cs, nc * csd_ave(max_cs) * sum(mean(csd)));
%text(5.7, y_max - 0.25, msg, 'FontName', 'Arial', 'FontSize', 12, 'BackgroundColor', 'w');


