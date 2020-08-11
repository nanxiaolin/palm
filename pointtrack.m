function pointtrack(object, event)
%
% pointtrack: tracks points identified by a mouse click in the 'fine render' PALM image
%
	global h_palmpanel proc handles;
	
	% stop other analytical processes
	stopcluster(0,0);
	
	set(handles.pointtrack, 'string', 'Stop PT', 'Callback', @stoppointtrack);
	
	% show a grid plot in the h_palmpanel figure
	figure(h_palmpanel); plot(-1:1, -1:1, 'b.'); axis tight; axis equal; grid on;
	Title('Tracking results of selected point');
	
	% clears the current palm panel axis and display a new title on the h_figfine;
	set(handles.figfine, 'Name', 'Point Tracking ...', 'WindowButtonDownFcn', @showtrackpoint);
	figure(handles.figfine);	Title('Click on the image to track points');
	
	proc.pointtrack = 1;
return
