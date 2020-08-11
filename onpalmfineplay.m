function onpalmfineplay(object, event)
% function that responds to palm play button in movie (time series)
%

    global params handles

    if params.highres_frames == 1
        dispmessage('No movie to play. Exiting ...');
        return;
    end


    stop = 0;
    set(handles.palmfineplay, 'callback', @stopmovie, 'String', 'Stop');

    while stop == 0

        frame_num = uint32(get(handles.palmfineslider, 'value'));

        frame_num = mod(frame_num, params.highres_frames) + 1;

        set(handles.palmfineslider,  'value', frame_num);
        onpalmfineslider(0,0);
        pause(0.02);
    end

    set(handles.palmfineplay, 'callback', @onpalmfineplay, 'String', 'Play');

    function stopmovie(object, event)
        stop = 1;
    end

end
