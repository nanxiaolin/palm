function [low high] = autoscale2d(data)
% this function autoscales data by binning it into 21 ranges and use the
% lowest 15% and highest 85% as the low and high display ranges
% here it only deals with 2-d image data
% 
% Usage: [low high] = autoscale2d(data)
%

	mind = min(min(data));
	data = data(find(data>mind));
	[r c] = size(data);		
	data = data(1:r*c);
	mind = min(min(data));
	maxd = max(max(data));
	nels = numel(data);

	nbins = ceil(nels/20);
	if nbins < 2000
		nbins = 2000;
	else 
		if nbins > 5000
			nbins = 5000;
		end
	end

	[n xout] = hist(data, nbins);
	hista = zeros(nbins, 1);

	for i = 1 : nbins
		hista(i) = sum(n(1:i)/nels);
	end
	
	ind_low = find(hista <= 0.001);	ind_low = max(ind_low);
	if numel(ind_low) == 0
		low = mind;
	else
		low = xout(ind_low);
	end

	ind_high = find(hista >= 0.999);  ind_high = min(ind_high);
	high = xout(ind_high);

	if high < 5 * (low + 1)
		high = 5 * (low + 1);
	end
end
