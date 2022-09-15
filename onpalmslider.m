function onpalmslider(object, event)
% function for responding to palm figure slider actions

    global params handles;

    if handles.palmslider == -1     % main figure has been closed
        warning('No image rendered. Please render image as time or z series first please.');
        return;
    end

    frame_num = uint32(get(handles.palmslider, 'value'));

    if frame_num > params.palm_frames
        frame_num = params.palm_frames;
    end

    % show the corresponding frame and update the title
    autoscale = get(handles.autoscale, 'value');
    if autoscale == 1
        [disp_low disp_high] = autoscale2d(params.palm_img(:, :, frame_num));
        set(handles.displow, 'string', num2str(disp_low, '%.1f'));
        set(handles.disphigh, 'string', num2str(disp_high, '%.1f'));
    else
        disp_low = str2num(get(handles.displow, 'string'));
        disp_high = str2num(get(handles.disphigh, 'string'));
    end


    % get the current x and y ranges
    figure(handles.palmfig); hold off;
    %set(gca, 'ActivePositionProperty', 'Position');
    xrange = xlim;
    yrange = ylim;
    %pos = get(gca, 'position');
    %set(gca,'drawmode', 'fast');

    %set(gca, 'visible', 'off');
    colormap(hot);
    imshow(params.palm_img(:, :, frame_num), [disp_low disp_high], 'initialmagnification', params.fig_mag, 'colormap', colormap);
    %colormap(hot);
    xlim(xrange); ylim(yrange);
    axis on; %axis image;

    %set(gca, 'position', [pos(1) pos(2) pos(3) pos(4)], 'visible', 'on');
    titlemsg = sprintf('Rendered at %d nm/pixel (frame %d of %d)', params.palm_pixelsize, frame_num, params.palm_frames);
    title(titlemsg);
    pause(0.001);

end