function cashowpanel(h_axes, h_figure, position)
% cashowpanel: function that displays the cluster analysis main panel in current axes
%
	global handles results;		% cluster analysis handles

	cla(h_axes); title(h_axes, '');
	set(h_axes, 'Visible', 'off');
	%delete(h_axes);
	
	handles.cah.panel = uipanel('Parent', h_figure, 'title', 'Cluster Analysis', 'units', 'pixels', 'Position', position);
	dispmessage('Cluster analysis activated.');
	
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	% draw the ripley's K panel and controls
	%handles.cah.panelripley = uipanel('Parent', handles.cah.panel, 'title', 'Ripley K Analysis', 'units', 'pixels', 'Position', [1 270 300 290]);
	handles.cah.btnripley = uicontrol('Parent', handles.cah.panel, 'string', 'K Function', 'units', 'pixels', 'Position', [15 245 80 25]);
	handles.cah.edNumSims = uicontrol('Parent', handles.cah.panel, 'Style', 'edit', 'enable', 'on', 'string', '500', 'Position', [105 247 30 22]);
	uicontrol('Parent', handles.cah.panel, 'Style', 'text', 'String', 'normalizing simulations', 'Position', [135 248 130 15]);
	set(handles.cah.btnripley, 'callback', @onkfunc);

	% create the ripley's k curve group of buttons
	handles.cah.btnpoolresultrpk = uicontrol('parent', handles.cah.panel, 'enable', 'off', 'String', 'Pool Result', 'Position', [15 210 70 25]);
	handles.cah.btnpoolclearrpk  = uicontrol('parent', handles.cah.panel, 'enable', 'off', 'String', 'Clear Pool', 'Position', [90 210 65 25]);
	handles.cah.btnpoolsaverpk   = uicontrol('parent', handles.cah.panel, 'enable', 'off', 'String', 'Save Pool', 'Position', [160 210 65 25]);
	handles.cah.btnpoolloadrpk   = uicontrol('parent', handles.cah.panel, 'enable', 'on', 'String', 'Load Pool', ...
											'callback', @onloadpool, 'Position', [230 210 65 25]);
	handles.cah.btnpoolplotrpk   = uicontrol('parent', handles.cah.panel, 'enable', 'off', 'String', 'Plot Pool', 'Position', [15 180 60 25]);
	handles.cah.chkshowpooledrpk = uicontrol('parent', handles.cah.panel, 'style', 'checkbox', 'enable', 'off', 'String', ...
											' Show Individual Plots', 'Position', [85 180 140 25]);
    
    set(handles.cah.btnpoolresultrpk, 'callback', @onpoolresult);
    
    % if results.ktests is not empty, enable 'clearpool' and 'plotpool' buttons
    if(results.ktests.num > 0)
    	set(handles.cah.btnpoolclearrpk, 'enable', 'on', 'callback', @onclearpool);
    	set(handles.cah.btnpoolplotrpk, 'enable', 'on', 'callback', @onplotpool);
    	set(handles.cah.chkshowpooledrpk, 'enable', 'on');
    	set(handles.cah.btnpoolsaverpk, 'enable', 'on', 'callback', @onsavepool);
    end
    
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % create the 'find cluster' group of controls
    handles.cah.btnfindcluster = uicontrol('parent', handles.cah.panel, 'String', 'Find Clusters', 'Position', [15 140 80 25]);
    set(handles.cah.btnfindcluster, 'callback', @onfindcluster);
    uicontrol('Parent', handles.cah.panel, 'Style', 'text', 'String', 'epsilon = ', 'Position', [105 142 55 15]);
    handles.cah.edepsilon = uicontrol('parent', handles.cah.panel, 'style', 'edit', 'enable', 'on', 'string', '0.26', 'Position', [162 140 30 22]);
    uicontrol('Parent', handles.cah.panel, 'Style', 'text', 'String', 'pixel', 'Position', [196 142 25 15]);
    handles.cah.chkshowclusterstat = uicontrol('parent', handles.cah.panel, 'style', 'checkbox', 'enable', 'on', 'String', ...
											' Show Cluster Stat Histogram', 'Position', [16 115 175 22]);
    
    % create the fc pool group of buttons
	handles.cah.btnpoolresultfcv = uicontrol('parent', handles.cah.panel, 'enable', 'off', 'String', 'Pool Result', 'Position', [230 115 65 25]);
	handles.cah.btnpoolclearfcv  = uicontrol('parent', handles.cah.panel, 'enable', 'off', 'String', 'Clear Pool', 'Position', [15 85 70 25]);
	handles.cah.btnpoolsavefcv  = uicontrol('parent', handles.cah.panel, 'enable', 'off', 'String', 'Save Pool', 'Position', [90 85 65 25]);
	handles.cah.btnpoolloadfcv  = uicontrol('parent', handles.cah.panel, 'enable', 'on', 'String', 'Load Pool', ...
											'callback', @onloadpool, 'Position', [160 85 65 25]);
	handles.cah.btnpoolplotfcv   = uicontrol('parent', handles.cah.panel, 'enable', 'off', 'String', 'Plot Pool', 'Position', [230 85 65 25]);
	
    set(handles.cah.btnpoolresultrpk, 'callback', @onpoolresult);
    
    % if results.fc is not empty, enable 'clearpool', 'savepool', 'plotpool' buttons
    
    if(results.fcv.num > 0)
    	set(handles.cah.btnpoolclearfcv, 'enable', 'on', 'callback', @onclearpool);
    	set(handles.cah.btnpoolplotfcv, 'enable', 'on', 'callback', @onplotpool);
    	set(handles.cah.btnpoolsavefcv, 'enable', 'on', 'callback', @onsavepool);
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % if there is no rendered window open, disable the 'ripley k' and 'find clusters' buttons
    if(handles.palmfig == -1)
    	set(handles.cah.btnripley, 'enable', 'off');
    	set(handles.cah.btnfindcluster, 'enable', 'off');
    	set(handles.cah.chkshowclusterstat, 'enable', 'off');
    end
   
    
    
