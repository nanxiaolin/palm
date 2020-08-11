function stopcluster(object, event)
% stopcluster: stop cluster analysis
% brings main axes image back

	global handles h_palmpanel proc;
	
	if proc.cluster == 0
		return;
	end
	
	delete(handles.cah.panel);
	if(proc.fileopen == 1)
		showsumimage;
	end
	
	set(handles.cluster, 'string', 'Clustering', 'callback', @clusteranalysis);
	dispmessage('Clustering analysis stopped.');
	proc.cluster = 0;
