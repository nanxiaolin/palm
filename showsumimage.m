function showsumimage
% showsumimage: shows the summed image of all particle coordinates
	global handles params proc;
	
	[low high] = autoscale2d(params.sumimg);
	figure(handles.palmpanel);
	
	hold off; imshow(params.sumimg, [low high]); axis on; box on; axis image; colormap(hot);
	title('Overlaid Particle Coordinates');
