function onmoviemode(object, event)
% function that responds to clicks on the MovieMode checkbox
% this toggles a switch for rendering in movie mode or sum mode
    
    global params handles
    
    % check the status of the checkbox
    status = get(handles.moviemode, 'value');
    
    switch status
        case 1
            dispmessage('Movie mode switched on. Will render new images as movies.');
            set(handles.movieframe, 'enable', 'on');
            set(handles.timecumulative, 'enable', 'on');
            params.moviemode = 1;
        case 0
            dispmessage('Movie mode switched off. Will render new images as sum images');
            set(handles.movieframe, 'enable', 'off');
            set(handles.timecumulative, 'enable', 'off');
            params.moviemode = 0;
    end
end