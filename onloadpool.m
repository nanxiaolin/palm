function onloadpool(object, event)
% 
% function onloadpool: load pooled curves into memory (to results.ktests structure)
% 
% remember that the curves were saved as 'ktests' which needs to be assigned to
% ktests.results substructure after loading into the memory
%
% Xiaolin Nan, UC Berkeley. 11/30/2011

	global h_palmpanel handles params results;
	
	switch(object)
		case handles.cah.btnpoolloadrpk
			pref_dir = params.pref_dir;
    		extension = {'*.kts', 'Ripley-K Test Results File (*.KTS)'};
    		[filename pathname] = uigetfile(extension, 'Choose a file to load the pooled Ripley k-curves', pref_dir);

		    if filename == 0
        		return;
		    end

    		[path name ext] = fileparts(filename);
    		fullname = fullfile(pathname, filename);
	
			% if there's already pooled results, then ask whether to cancel, merge, or clear current results
			% only to make sure that the ktests.last curve is not overwritten in any cases
			if(results.ktests.num == 0)
				load(fullname, '-MAT');
				last = results.ktests.last;
				results.ktests = ktests;
				results.ktests.last = last;
				m = sprintf('Pool %s loaded.', fullname);
				dispmessage(m);
			else
				answ = questdlg('Pool exists. Overwrite?', 'Choose an action:', 'Overwrite', 'Merge', 'Cancel', 'OK');
		
				switch(answ)
					case 'Overwrite'
						%disp('Overwrite');
						load(fullname, '-mat');
						last = results.ktests.last;
						results.ktests = ktests;
						results.ktests.last = last;
					case 'Merge'
						%disp('Merge');
						load(fullname, '-mat');
						results.ktests.num  = results.ktests.num + ktests.num;
						results.ktests.rpcs = [results.ktests.rpcs ktests.rpcs];
					case('Cancel')
						return;
				end	
			end
	
			% if there's curves in the pool, enable certain buttons
			if(results.ktests.num > 0)
				set(handles.cah.btnpoolclearrpk, 'enable', 'on', 'callback', @onclearpool);
				set(handles.cah.btnpoolplotrpk, 'enable', 'on', 'callback', @onplotpool);
				set(handles.cah.chkshowpooledrpk, 'enable', 'on');
				set(handles.cah.btnpoolsaverpk, 'enable', 'on', 'callback', @onsavepool);
			else
				set(handles.cah.btnpoolclearrpk, 'enable', 'off', 'callback', @onclearpool);
				set(handles.cah.btnpoolplotrpk, 'enable', 'off', 'callback', @onplotpool);
				set(handles.cah.chkshowpooledrpk, 'enable', 'off');
				set(handles.cah.btnpoolsaverpk, 'enable', 'off', 'callback', @onsavepool);
			end

		case handles.cah.btnpoolloadfcv
			pref_dir = params.pref_dir;
    		extension = {'*.csh', 'Cluster Size Histogram File (*.CSH)'};
    		[filename pathname] = uigetfile(extension, 'Choose a file to load', pref_dir);

		    if filename == 0
        		return;
		    end

    		[path name ext] = fileparts(filename);
    		fullname = fullfile(pathname, filename);
	
			% if there's already pooled results, then ask whether to cancel, merge, or clear current results
			% only to make sure that the ktests.last curve is not overwritten in any cases
			if(results.fcv.num == 0)
				load(fullname, '-MAT');
				last = results.fcv.last;
				results.fcv = fcv;
				results.fcv.last = last;
				m = sprintf('Pool %s loaded.', fullname);
				dispmessage(m);
			else
				answ = questdlg('Pool exists. Overwrite?', 'Choose an action:', 'Overwrite', 'Merge', 'Cancel', 'OK');
		
				switch(answ)
					case 'Overwrite'
						%disp('Overwrite');
						load(fullname, '-mat');
						last = results.fcv.last;
						results.fcv = fcv;
						results.fcv.last = last;
					case 'Merge'
						%disp('Merge');
						load(fullname, '-mat');
						results.fcv.num  = results.fcv.num + fcv.num;
						results.fcv.sizes = [results.fcv.sizes; fcv.sizes];
					case('Cancel')
						return;
				end	
			end
	
			% if there's histograms in the pool, enable certain buttons
			if(results.fcv.num > 0)
				set(handles.cah.btnpoolclearfcv, 'enable', 'on', 'callback', @onclearpool);
				set(handles.cah.btnpoolplotfcv, 'enable', 'on', 'callback', @onplotpool);
				set(handles.cah.btnpoolsavefcv, 'enable', 'on', 'callback', @onsavepool);
			else
				set(handles.cah.btnpoolclearfcv, 'enable', 'off', 'callback', @onclearpool);
				set(handles.cah.chkshowpooledfcv, 'enable', 'off');
				set(handles.cah.btnpoolsavefcv, 'enable', 'off', 'callback', @onsavepool);
			end
		
		end
