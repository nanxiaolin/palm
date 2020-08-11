function onpalmfineslider(object, event)
% function for responding to palm figure slider actions

global params handles;

    if handles.palmfineslider == -1     % main figure has been closed
        warning('No fine image rendered. Please render image as time or z series first please.');
        return;
    end

   frame_num = uint32(get(handles.palmfineslider, 'value'));
   
   if frame_num > params.highres_frames
       frame_num = params.highres_frames;
   end
   
   % show the corresponding frame and update the title
   autoscale = get(handles.autoscale, 'value');
   if autoscale == 1
       [disp_low disp_high] = autoscale2d(params.palm_img_highres(:, :, frame_num));
       set(handles.displow, 'string', num2str(disp_low, '%.1f'));
       set(handles.disphigh, 'string', num2str(disp_high, '%.1f'));
   else
       disp_low = str2num(get(handles.displow, 'string'));
       disp_high = str2num(get(handles.disphigh, 'string'));
   end
   
   
   % get the current x and y ranges
   figure(handles.figfine); hold on;
   feature_size = params.feature_size;
   [palm_ydim palm_xdim] = size(params.palm_img_highres(:, :, 1));
   
   [ind x0 y0 x1 y1] = getpointsinview();
   
   show_y = 2*feature_size : palm_ydim - 2*feature_size;
   show_x = 2*feature_size : palm_xdim - 2*feature_size;
   hold off; imshow(params.palm_img_highres(show_y, show_x, frame_num), [disp_low disp_high]);
   axis on; %axis image; 
   colormap(hot);
   xlabel('X (nm)');	ylabel('Y (nm)');
   titlemsg = sprintf('PALM Image Rendered at 1 nm/pixel (frame %d of %d). Viewport = (%d, %d) - (%d, %d)', frame_num, params.highres_frames, x0, x1, y0, y1);
   title(titlemsg);
   
   
   pause(0.01);
   
end