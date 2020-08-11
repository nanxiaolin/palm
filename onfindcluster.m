function onfindcluster(object, event)
%
% function onfindcluster: callback function to find clusters
%   reads 'epsilon' and 'showstat' parameters and call fcviewport(epsilon, showstat) function
%   to display a fine PALM image with find cluster results

	global h_palmpanel handles;
	
	epsilon = str2num(get(handles.cah.edepsilon, 'string'));
	showstat = get(handles.cah.chkshowclusterstat, 'value');
	
	fcviewport(epsilon, showstat);
	
	set(handles.cah.btnpoolresultfcv, 'enable', 'on', 'callback', @onpoolresult);
