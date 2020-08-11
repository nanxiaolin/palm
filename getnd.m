function nd = getnd(type)
% this function retrieves the current noise distribution
% for use with cluster simulations
% usage:
%    nd = getnd(type)
% type:
%    1 = retrieve the original noise data
%    2 = retrieve a distrubtion of noise distribution (in nm)

  global h_palmpanel handles params;
  
  if nargin == 0
  	type = 2;
  end
  
  % get the x and y errors
  r = sqrt(params.scf(:, 6).^2 + params.scf(:, 7).^2) ./ sqrt(params.scf(:, 5)); 
  px = str2num(get(handles.pixelsize, 'string'));
  
  r = r * px;
  
  if type == 1 	% return the noise data
  	nd = r;
  	return;
  else
  	[h n]= hist(r, -1.25:2.5:202.5);
  
  	nd = zeros(50, 2);
  	nd(:, 1) = n(2:51);
  	nd(:, 2) = h(2:51);
  end
  
  %bar(nd(:, 1), nd(:, 2)); box on; grid on; axis tight;
