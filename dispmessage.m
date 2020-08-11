function dispmessage(message)
	global h_palmpanel;

	h = findobj(h_palmpanel, 'tag', 'txtMessage');
    set(h, 'string', message);	
end
