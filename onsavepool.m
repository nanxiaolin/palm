function onsavepool(object, event)
	global h_palmpanel handles params results;
	
	switch(object)
		case handles.cah.btnpoolsaverpk
			pref_dir = params.pref_dir;
    		extension = {'*.kts', 'Ripley-K Test File (*.KTS)'};
    		[filename pathname] = uiputfile(extension, 'Choose a file name to save the pooled Ripley k-curves', pref_dir);

    		if filename == 0
        		return;
    		end

    		[path name ext] = fileparts(filename);
    		fullname = fullfile(pathname, filename);
			
			ktests = results.ktests;
			save(fullname, 'ktests', '-MAT');
			m = sprintf('Pool saved as %s', fullname);
	
			dispmessage(m);
			
		case handles.cah.btnpoolsavefcv
			pref_dir = params.pref_dir;
    		extension = {'*.csh', 'Cluster Size Histogram File (*.CSH)'};
    		[filename pathname] = uiputfile(extension, 'Choose a file name to save', pref_dir);

    		if filename == 0
        		return;
    		end

    		[path name ext] = fileparts(filename);
    		fullname = fullfile(pathname, filename);
			
			fcv = results.fcv;
			save(fullname, 'fcv', '-MAT');
			m = sprintf('Pool saved as %s', fullname);
	
			dispmessage(m);			
	end
