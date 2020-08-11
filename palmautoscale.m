function palmautoscale(object, event)
% 
% palmautoscale: autoscales the rendered palm imaged when the users
% disables or enables the display high and low controls
	global handles params;

	status = get(handles.autoscale, 'value');
	
	if status == 1		% enables autoscale	
		[disp_low disp_high] = autoscale2d(params.palm_img);
		%disp_high = 0.2* max(max(palm_img))
		set(handles.displow, 'string', num2str(disp_low, '%.1f'), 'enable', 'off');
		set(handles.disphigh, 'string', num2str(disp_high, '%.1f'), 'enable', 'off');
		%figure(handles.palmfig);
		%imshow(params.palm_img, [disp_low disp_high]); colormap(hot); axis on; axis image; 
		palmrender(object, event);
	else
		set(handles.displow, 'enable', 'on');
		set(handles.disphigh, 'enable', 'on');
	end		
end

