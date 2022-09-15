function showsumimage
% showsumimage: shows the summed image of all particle coordinates
% the function was updated on 02/09/2020 to incorporate information stored
% in the .drift subfolder.
% while the .coords field is almost never (except when unapplying the drift
% corrections) changed, the sumimg is where the user visually sees the
% effect of applying the drift corrections.

	global handles params;
	
    % first look for the .drift field
    if ~isfield(params, 'drift')
        %disp('no existing .drift field.');
        params.drift.x = zeros(1, params.frames);
        params.drift.y = zeros(1, params.frames);
    end
      
    x_raw = params.coords(:, 2)';
    y_raw = params.coords(:, 3)';
    f_num = params.coords(:, 1);
    idx = 1 : length(x_raw); 
    
    %whos
    
    % apply the corrections
    x_raw(idx) = x_raw(idx) - params.drift.x(f_num(idx));
    y_raw(idx) = y_raw(idx) - params.drift.y(f_num(idx));                        
    ydims = ceil(abs(y_raw));  y_size = max(ydims);
    xdims = ceil(abs(x_raw));  x_size = max(xdims);
    
    % move pixels at the boundary to the interior
    ydims(ydims == 0) = 1;
    xdims(xdims == 0) = 1;
    
    params.sumimg = zeros(y_size, x_size);

    for i = 1 : length(x_raw)
       params.sumimg(ydims(i), xdims(i)) = params.sumimg(ydims(i), xdims(i)) + 1;
    end

    % make sure fiducials do not appear as super-bright points in the low res image
    sumimg = params.sumimg;
    
    sumimg(find(sumimg > params.frames/60)) = params.frames/60;
	[low, high] = autoscale2d(sumimg);
	figure(handles.palmpanel);
	
	hold off; imshow(sumimg, [low high], 'Parent', handles.axes); axis on; box on; axis image; colormap(handles.axes, 'hot');
    set(gca, 'FontSize', 9);
	title('Summed Image of Localizations');
    
    % generate the sum image (for display on the main panel)
