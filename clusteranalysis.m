function clusteranalysis(object, event)
%
% clusteranalysis: main function for cluster analysis
%   displays buttons and controls for cluster analysis parameters
%   

	global h_palmpanel proc handles;
	
    	
	% stops point track if it is in process
	if proc.pointtrack == 1
		stoppointtrack;
	end
	
	% clear the main axis and displays a panel showing 'Cluster Analysis'
	cashowpanel(handles.axes, h_palmpanel, [405 56 310 300]);
	
	% set the string and callback to stop cluster analysis
	set(handles.cluster, 'string', 'Stop CA', 'enable', 'on', 'callback', @stopcluster);
	proc.cluster = 1;
