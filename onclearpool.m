function onclearpool(object, event)
% function that clears the pooled data
	global h_palmpanel handles params results;

	switch(object)
		case handles.cah.btnpoolclearrpk
			%userdata = get(h_palmpanel, 'userdata');
			results.ktests.rpcs = [];
			results.ktests.num = 0;
			results.ktests.step = [];
	
			%set(h_palmpanel, 'userdata', userdata);

			% disable the plot function
			set(handles.cah.btnpoolplotrpk, 'enable', 'off');
			set(handles.cah.btnpoolclearrpk, 'enable', 'off');
			set(handles.cah.btnpoolsaverpk, 'enable', 'off');
			set(handles.cah.chkshowpooledrpk, 'enable', 'off');
	
			if(isempty(results.ktests.last) == 0)
				set(handles.cah.btnpoolresultrpk, 'enable', 'on');
			end
	
			dispmessage('All pooled RIP curves cleared from results.');

		case handles.cah.btnpoolclearfcv
			results.fcv.sizes = [];
			results.fcv.num = 0;

			% disable certain functions
			set(handles.cah.btnpoolplotfcv, 'enable', 'off');
			set(handles.cah.btnpoolclearfcv, 'enable', 'off');
			set(handles.cah.btnpoolsavefcv, 'enable', 'off');
	
			if(isempty(results.fcv.last) == 0)
				set(handles.cah.btnpoolresultfcv, 'enable', 'on');
			end
	
			dispmessage('All pooled cluster size histograms cleared from results.');
					
	end

