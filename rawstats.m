function rawstats(object, event)
% rawstats(object, event)
%  this function calculates a few histograms for the raw particles (unsorted)
%  list of output histograms:
%	fitting goodness / sigma / Eccentricity / RMS
%  raw intensity is combined into 'sorted histograms'
%  these distributions can then be used to guide the settings of sorting parameters

  global h_palmpanel handles params;

  nplots = 4;		% Number of histograms to show
  
  if(handles.figstats == -1)
	h = figure; 
	handles.figstats = h;
  else
	h = handles.figstats;
  end
  set(h, 'NumberTitle', 'off', 'Name', 'Histograms for Unsorted Particles', 'Position', [100 100 500 650]);
  set(h, 'CloseRequestFcn', @onfigstatsclosed);
  figure(h); clf;

  % RMS distribution
  n = 0:0.2:100; 	bshow = 100;
  rms = params.coords(:, 4) ./ params.coords(:, 7);
  y = hist(rms, n);		y = 100 * y/max(y(1:bshow));
  subplot(nplots, 1, 1); bar(n(1:bshow), y(1:bshow), 'EdgeColor', [0 0.4 0], 'FaceColor', [0 0.6 0]);
  grid on; xlim([0 20]); ylim([0 110]);
  x = 0:2:20; set(gca, 'XTick', x, 'XTickLabel', sprintf('%d|', x), 'XMinorTicks', 'on');
  xlabel('RMS'); ylabel('% Particles');

  % fitting goodness histogram
  n = 0:0.005:1; bshow = 150;
  ind = find(rms <= 12);
  y = hist(params.coords(ind, 8), n); y = 100.0*y/max(y(1: bshow));
  subplot(nplots, 1, 2); bar(n(1:bshow), y(1:bshow), 'EdgeColor', [0 0.4 0], 'FaceColor', [0 0.6 0]);
  grid on; %title('Fitting Goodness (Relative Residue after Fitting)');
  xlim([0 0.75]); ylim([0 110]);
  x = 0:0.1:0.8; set(gca, 'XTick', x, 'XTickLabel', sprintf('%.3f|', x), 'XMinorTicks', 'on');
  xlabel('Goodness'); ylabel('% Particles');

  % sigma_x, sigma_y histograms
  n = 0: 0.03: 3; bshow = 1:100;	
  y = hist(params.coords(ind, 5), n);	y = 100*y/max(y(bshow));
  subplot(nplots, 1, 3); bar(n(bshow), y(bshow), 'EdgeColor', [0 0.4 0], 'FaceColor', [0 0.6 0], 'BarWidth', 1);
  y = hist(params.coords(ind, 6), n);  y = 100*y/max(y(bshow));
  hold on; bar(n(bshow), y(bshow), 'EdgeColor', [0.4 0 0], 'FaceColor', [0.6 0 0], 'BarWidth', 1);
  legend('Sigma in X', 'Sigma in Y'); %Title('Sigma from Fitting');
  xlabel('Sigma (pixel)'); ylabel('% Particles'); 
  xlim([0 3]); ylim([0 110]);
  grid on;  x = 0:0.5:3; set(gca, 'XTick', x, 'XTickLabel', sprintf('%.1f|', x), 'XMinorTicks', 'on');
	
  % Eccentricity (sigma_x / sigma_y)
  n = 0:0.025:5; bshow = 1:100;
  y = hist(params.coords(ind, 5) ./ params.coords(ind, 6), n);   y = 100*y/max(y(bshow));
  subplot(nplots, 1, 4); bar(n(bshow), y(bshow), 'EdgeColor', [0 0.4 0], 'FaceColor', [0 0.6 0], 'BarWidth', 1);
  ylim([0 110]); xlim([0 2.5]);
  grid on; x = 0:0.25:2.5; set(gca, 'XTick', x, 'XTickLabel', sprintf('%.1f|', x), 'XMinorTicks', 'on');
  xlabel('Eccentricity (Sig\_X / Sig\_Y)'); ylabel('% Particles');  
  
  drawnow;

