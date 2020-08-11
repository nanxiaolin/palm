function onfigpalmclosed(object, event)
%
% this handles the event when the palm figure is closed
% reset the internal handle holder to -1
	global handles;
	
	if(handles.palmfig == -1) 
		return;
	end
	
	delete(handles.palmfig);
	handles.palmfig = -1;
    
    if handles.figfine ~= -1
        delete(handles.figfine);
        handles.figfine = -1;
    end
    
    if handles.palmslider ~= -1
        handles.palmslider = -1;
    end
	
	stopcluster(0,0);

	set(handles.highres, 'enable', 'off');
	set(handles.lowres, 'enable', 'off');
    set(handles.palmexport, 'enable', 'off');
	%set(handles.cluster, 'enable', 'off');
