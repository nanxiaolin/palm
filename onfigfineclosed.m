function onfigfineclosed(object, event)
%
% onfigfineclosed: handles event when Fine Render Window is closed

	global handles;

	if(handles.figfine == -1) 
		return; 
	end

	stoppointtrack(0, 0);
	%stopcluster(0, 0);
    
	delete(handles.figfine);
	handles.figfine = -1;
    
    if handles.palmfineslider ~= -1
        handles.palmfineslider = -1;
    end
    
	%set(handles.cluster, 'enable', 'off');
	
	set(handles.pointtrack, 'enable', 'off');
