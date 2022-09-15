function palmlowres(object, event)
% this function generates a low resolution image for the current palm image
% 

	global params;

	[ind, x0, y0, x1, y1] = getpointsinview();
	width  = (x1 - x0 + 1) / params.palm_mag;
	height = (y1 - y0 + 1) / params.palm_mag;

	if(width >=100 || height >=100)	% image will be too large
	  ans = questdlg('Area of interest is over 100 pixels. It will take a long time to generate the final image. Continue?', 'Warning!');
	  if strcmp(ans, 'No')
		return;
	  end
	end

	dispmessage('Generating low resolution image. Please wait ...');
	pause(0.002);

	start_img = params.palm_img(y0:y1, x0:x1);

	low_img = conv2(start_img, params.psf, 'same');
	low_img = imgbin(low_img, params.palm_mag);
	dispmessage('Generating low resolution image. Please wait ... Finished.');
	pause(0.002);
	[low, high] = autoscale2d(low_img);
	init_mag = params.fig_mag * params.palm_mag * (params.palm_ydim/(y1 - y0 + 1));

	% show the low res image
	h = figure; set(h, 'Position', [300 100 500 500]);
	imshow(low_img, [low high], 'InitialMagnification', init_mag); 
	colormap(gca, 'hot'); axis on; axis image;
	set(gcf, 'name', 'Low Resolution Image', 'Numbertitle', 'off');
end
