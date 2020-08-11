function onpalmplay(object, event)
% function that responds to palm play button in movie (time series)
%

global params handles

if params.palm_frames == 1
    dispmessage('No movie to play. Exiting ...');
    return;
end


stop = 0;
set(handles.palmplay, 'callback', @stopmovie, 'String', 'Stop');

while stop == 0
   
   frame_num = uint32(get(handles.palmslider, 'value'));
   
   frame_num = mod(frame_num, params.palm_frames) + 1; 
    
   set(handles.palmslider,  'value', frame_num);
   onpalmslider(0,0);
   pause(0.02);
end

set(handles.palmplay, 'callback', @onpalmplay, 'String', 'Play');

function stopmovie(object, event)
    stop = 1;
end

end
