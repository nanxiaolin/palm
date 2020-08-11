todolist:

put all handles into global containers for easy access, so we do not need to get 'userdata' all the time.

h_palmpanel				the main panel handle

params.
	pref_dir			prefered data folder

proc.
	pointtrack 	= 1		point track in progress
				= 0		point track not in progress
	cluster		= 1		cluster analysis in progress
				= 0 	otherwise

handles.
	cah			=		handles for cluster analysis controls
		.panel			panel handle (the container object)
		.
		.
	loadfile
	palmsort
	
