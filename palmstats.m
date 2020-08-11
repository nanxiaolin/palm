function palmstats(object, event)
% palmstats(object, event)
%  this function calculates a few histograms for the current loaded PALM coordinate file
%  list of output histograms:
%	particle intensity (sum intensity)
%

  global h_palmpanel handles params;
  userdata = get(h_palmpanel, 'userdata');

  is_sorted = numel(params.scf);
  if(is_sorted)
	  	nplots = 3;		% Number of histograms to show
  
	  	% show the sum intensity plot
		if(handles.figstats == -1)
	  	   h = figure; 
		   handles.figstats = h;
		else
		   h = handles.figstats;
		end
 		set(h, 'NumberTitle', 'off', 'Name', 'Histograms for Sorted Particles', 'Position', [100 100 500 650]);
  		set(h, 'CloseRequestFcn', @onfigstatsclosed);
        figure(h); clf;

	  	% intensity histograms
	  	n = 0:1000:200000; bshow = 1:150; bwidth = 0.6;
	  	ints = 2*pi* params.coords(:, 4) .* params.coords(:, 5) .* params.coords(:, 6);
	  	y = hist(ints, n); y = 100.0*y/max(y(bshow));
	  	subplot(nplots, 1, 1); bar(n(bshow), y(bshow), 'EdgeColor', [0 0.4 0], 'FaceColor', [0 0.6 0]);
	  	xlim([0 150000]); ylim([0 105]);
	  	grid on; title('Particle sum intensity (from Gaussian Fitting)');
	  	x = 0:30000:150000; set(gca, 'XTick', x, 'XTickLabel', sprintf('%.0f|', x), 'XMinorTicks', 'on');
	  	xlabel('Sum Intensity (a.u.)'); ylabel('% Particles');
		y = hist(params.scf(:, 3), n); y = 100.0*y/max(y(bshow));
	  	hold on; bar(n(bshow), y(bshow), 'EdgeColor', [0.4 0 0], 'FaceColor', [0.6 0 0]);
		legend('Unsorted particles', 'Sorted particles');
	
	 	% position errors in x, y, and total
	  	ind = find(params.scf(:, 6) < 5);
	  	n = 0: 0.01: 1.5; bshow = 2:100;	
	  	x_err = params.scf(ind,6) ./ sqrt(params.scf(ind, 5));
	  	y = hist(x_err, n);		y = 100*y/max(y(bshow));
	  	subplot(nplots, 1, 2); bar(n(bshow), y(bshow), 'EdgeColor', [0 0.4 0], 'FaceColor', [0 0.6 0], 'BarWidth', 1);
	  	y_err = params.scf(ind,7) ./ sqrt(params.scf(ind, 5));
	  	y = hist(y_err, n);    y = 100*y/max(y(bshow));
	  	hold on; bar(n(bshow), y(bshow), 'EdgeColor', [0.4 0 0], 'FaceColor', [0.6 0 0], 'BarWidth', 1);
	  	r_err = sqrt(x_err .^ 2 + y_err .^2);
	  	y = hist(r_err, n);		y = 100*y/max(y(bshow));
	  	hold on; bar(n(bshow), y(bshow), 'EdgeColor', [0.2 0.2 0.7], 'FaceColor', [0.4 0.4 0.8], 'BarWidth', 1);
	  	legend('X Std Err', 'Y Std Err', 'Total Err'); title('Position Errors');
	  	xlabel('Error (pixel)'); ylabel('% Particles'); ylim([0 110]);
	  	grid on;  x = 0:0.2:2; set(gca, 'XTick', x, 'XTickLabel', sprintf('%.1f|', x), 'XMinorTicks', 'on');
	
	  	% number of frames histograms
	  	ind = find(params.scf(:, 5) <= 50);
	  	n = 0:100; bshow = 1:60;
	  	y = hist(params.scf(ind, 5), n);   y = 100*y/max(y(bshow));
	  	subplot(nplots, 1, 3); bar(n(bshow), y(bshow), 'EdgeColor', [0 0.4 0], 'FaceColor', [0 0.6 0], 'BarWidth', 1);
	  	title('Number of Frames per Particle');
	  	axis tight; grid on; x = 0:5:60; set(gca, 'XTick', x, 'XTickLabel', sprintf('%d|', x), 'XMinorTicks', 'on');
	  	xlabel('Number of Frames'); ylabel('% Particles');  ylim([0 110]);

		drawnow;
	else
		msgbox('Particle coordinates have not been sorted yet. Click SORT first.', 'Error');
	end
  
  

