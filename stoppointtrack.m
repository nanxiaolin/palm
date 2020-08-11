function stoppointtrack(object, event)
% subroutine that stops pointtrack

	global proc handles;
	
	if proc.pointtrack == 0
		return;
	end
	
	set(handles.pointtrack, 'string', 'Point Track', 'Callback', @pointtrack);
	
	% delete the current markers
	cud = get(handles.figfine, 'userdata');
	if(cud.h_curpoint ~= -1)
		delete(cud.h_curpoint);
	end
	cud.h_curpoint = -1;
	set(handles.figfine, 'userdata', cud);
	
	% put the title of fine palm image back
	if(handles.figfine ~= -1)
		set(handles.figfine, 'Name', 'Fine PALM image for current view port', 'WindowButtonDownFcn', '');
		figure(handles.figfine); Title('PALM Image Rendered at 1 nm/pixel');
	end
	
	% reset the current axes of h_palmpanel;
	set(handles.axes, 'visible', 'on');
	showsumimage;
	
	proc.pointtrack = 0;
return
