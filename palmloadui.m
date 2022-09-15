function palmloadui
%
% palmloadui: loads the palm panel user interface and initializes handles, params, etc.
%
% last modified: 07/23/2010
% 
% Update on 03/25/2016
%   1. Modified the main panel to allow more function buttons
%   2. Added 'Frame range' option and 'Movie' button to 'Rendering'
%

	global h_palmpanel handles params results proc;

    p = fileparts(mfilename('fullpath'));
    h = open([p '/fig/palmpanel.fig']);
	h_palmpanel = h;
    handles.palmpanel = h;
	
    userdata = get(h, 'userdata');
	set(h, 'CloseRequestFcn', @onpalmpanelclosed);

	% set the callback functions of buttons
	handles.loadfile = findobj(h, 'tag', 'btnPalmLoadFile');
 	set(handles.loadfile, 'callback', @palmloadfile);
	handles.palmsort = findobj(h, 'tag', 'btnSort');
	set(handles.palmsort, 'enable', 'off', 'callback', @palmsort);
	handles.renderpalm = findobj(h, 'tag', 'btnPalmRender');
	set(handles.renderpalm, 'enable', 'off', 'callback', @palmrender);
	handles.highres = findobj(h, 'tag', 'btnFineImage');
	set(handles.highres, 'enable', 'off', 'callback', @palmhighres);
	handles.lowres = findobj(h, 'tag', 'btnPalmLowRes');
	set(handles.lowres, 'enable', 'off', 'callback', @palmlowres);
	handles.palmexport = findobj(h, 'tag', 'btnPalmExport');
	set(handles.palmexport, 'enable', 'off', 'callback', @palmexport);
    handles.palmalign = findobj(h, 'tag', 'btnPalmAlign');
    set(handles.palmalign, 'enable', 'off', 'callback', @palmalign);
    %handles.makecor = findobj(h, 'tag', 'btnMakeCoor');
    %set(handles.makecor, 'callback', @makecorfiles);
    
	handles.axes = findobj(h, 'tag', 'axCoord');
	set(handles.axes, 'visible', 'off');
	set(h, 'CurrentAxes', handles.axes);

	% disable the display high and low edit boxes
	handles.autoscale = findobj(h, 'tag', 'chkPalmAutoscale');	
	set(handles.autoscale, 'callback', @palmautoscale, 'value', 1, 'enable', 'off');
	handles.disphigh = findobj(h, 'tag', 'edPalmDispHigh');
	handles.displow  = findobj(h, 'tag', 'edPalmDispLow');
	set(handles.disphigh, 'enable', 'off');
	set(handles.displow,  'enable', 'off');
    handles.moviemode = findobj(h, 'tag', 'chkMovieMode');
    handles.movieframe = findobj(h, 'tag', 'edMovieCombineFrame');
    set(handles.moviemode, 'enable', 'off', 'callback', @onmoviemode);
    set(handles.movieframe, 'enable', 'off');
    handles.timecumulative = findobj(h, 'tag', 'chkTimeCumulative');
    set(handles.timecumulative, 'enable', 'off', 'value', 0);
    handles.showlandmark = findobj(h, 'tag', 'chkShowLandmark');

	% initialize the edit box controls
	handles.thresh 	  = findobj(h, 'tag', 'edRMSThresh');
	handles.comframes = findobj(h, 'tag', 'edPointCombineFrames');
	handles.comdist   = findobj(h, 'tag', 'edCombineDistance');
	handles.mingood   = findobj(h, 'tag', 'edMinGoodness');
	handles.maxeccen  = findobj(h, 'tag', 'edMaxEccentricity');
	handles.pixelsize = findobj(h, 'tag', 'edPixelSize');
	handles.renderpix = findobj(h, 'tag', 'edRenderPixelSize');
	handles.renderres = findobj(h, 'tag', 'edRenderResolution');
    handles.startframe = findobj(h, 'tag', 'edStartFrame');
    handles.endframe  = findobj(h, 'tag', 'edEndFrame');
    

	% analysis buttons
	handles.palmstats = findobj(h, 'tag', 'btnPALMStats');
	set(handles.palmstats, 'enable', 'off', 'callback', @palmstats);
	handles.rawstats = findobj(h, 'tag', 'btnRawStats');
	set(handles.rawstats, 'enable', 'off', 'callback', @rawstats);
	handles.pointtrack = findobj(h, 'tag', 'btnPointTrack');
	handles.cluster = findobj(h, 'tag', 'btnClusterAnalysis');	
	set(handles.cluster, 'enable', 'off', 'callback', @clusteranalysis);
    %handles.findfiducials = findobj(h, 'tag', 'btnFindFiducials');
    %set(handles.findfiducials, 'enable', 'off', 'callback', @findfiducials);
    %handles.driftcorrect = findobj(h, 'tag', 'btnDriftCorrection');
    %set(handles.driftcorrect, 'enable', 'off', 'callback', @ondriftcorrect);
    handles.joincorfiles = findobj(h, 'tag', 'btnJoincor');
    set(handles.joincorfiles, 'enable', 'off', 'callback', @joincorfiles);
    handles.driftcorr = findobj(h, 'tag', 'btnDrift');
    set(handles.driftcorr, 'enable', 'off', 'callback', @driftcorrect);
    
	% a few message displays
	handles.dispraw    = findobj(h, 'tag', 'dispRawParticles');
	handles.dispsorted = findobj(h, 'tag', 'dispSortedParticles');
	handles.disppf = findobj(h, 'tag', 'dispParticleFinding');
	handles.dispfit = findobj(h, 'tag', 'dispFitting');
	handles.dispframes = findobj(h, 'tag', 'dispFrames');
    handles.txtMessage = findobj(h, 'tag', 'txtMessage');

	% set default pref dir attribute
	params.pref_dir = '/home/xiaolin/Data/Sorted';	
    params.moviemode = 0;

	% initialize a few figure handles
	handles.palmfig   = -1;		% figure to show PALM images
	handles.figstats  = -1;		% figure to show histograms
	handles.figfine   = -1;
	handles.figcoarse = -1;
    handles.figdrift = -1;
    handles.palmslider = -1;
    handles.palmfineslider = -1;
    handles.figmakecor = -1;

    % initialize results container 
    results.ktests.num = 0;          % number of k-tests stored
    results.ktests.last = [];          % k-test results
    results.ktests.step = [];     % k=test stepss
    results.ktests.rpcs = [];
    %results.ktests.last_param = [];
    %results.ktests.param = [];
    
    results.fcv.num   = 0;	  		  % fcviewport test results
    results.fcv.sizes = [];
    results.fcv.last = [];
    
    % initialize status variables
	proc.pointtrack = 0;
	proc.cluster = 0;
	proc.fileopen = 0;
    
	set(h, 'name', 'PALM Rendering');
end


