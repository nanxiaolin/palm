function onpoolresult(object, event)
% 
% function onpoolresult: callback function that pools the current analysis results.
% 
% uses the 'object' (handles of buttons clicked) to distinguish which structure the
% results should be pooled to.
%	handles.cah.btnpoolrktripley k test result
%
	global results handles;
	
	switch(object)
		case handles.cah.btnpoolresultrpk		% pool rpk results
		    if(isempty(results.ktests.last))
				return;
			end

			if(results.ktests.num == 0)
				results.ktests.rpcs = results.ktests.last;
			else
				results.ktests.rpcs = [results.ktests.rpcs results.ktests.last];
			end
	
			%results.ktests.last = [];
			results.ktests.num = results.ktests.num + 1;

			set(handles.cah.btnpoolresultrpk, 'enable', 'off'); % does not allow pooling twice
			set(handles.cah.btnpoolclearrpk, 'enable', 'on', 'callback', @onclearpool);
			set(handles.cah.btnpoolplotrpk, 'enable', 'on', 'callback', @onplotpool);
			set(handles.cah.chkshowpooledrpk, 'enable', 'on');
			set(handles.cah.btnpoolsaverpk, 'enable', 'on', 'callback', @onsavepool);

			dispmessage('Ripley K curve pooled to results.');
		
		case handles.cah.btnpoolresultfcv		% pool find cluster results
			if(isempty(results.fcv.last))
				return;
			end
			
			if(results.fcv.num == 0)
				results.fcv.sizes =results.fcv.last;
			else
				results.fcv.sizes = [results.fcv.sizes; results.fcv.last];
			end
			
			results.fcv.num = results.fcv.num + 1;
			
			set(handles.cah.btnpoolresultfcv, 'enable', 'off'); % does not allow pooling twice
			set(handles.cah.btnpoolclearfcv, 'enable', 'on', 'callback', @onclearpool);
			set(handles.cah.btnpoolplotfcv, 'enable', 'on', 'callback', @onplotpool);
			set(handles.cah.btnpoolsavefcv, 'enable', 'on', 'callback', @onsavepool);

			dispmessage('Find cluster result pooled to results.');
	end


