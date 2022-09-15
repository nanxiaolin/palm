function onfigdriftclosed(object, event)
%
% this handles the event when the palm figure is closed
% reset the internal handle holder to -1
	global handles;
	
	if(handles.figdrift == -1) 
        % sometimes multiple drift windows pop due to accidentally mouse
        % clicks. also close those windows down.
        delete(findall(0, 'type', 'figure', 'name', 'Drift Correction'));
    else
        delete(handles.figdrift);
        handles.figdrift = -1;
    end
    
    % enable the drift correction button again
    set(handles.driftcorr, 'enable', 'on');
	