function palmloadfile(object, event)
%
% palmloadfile: file loading routine

	global h_palmpanel proc handles params;

    pref_dir = params.pref_dir;
    extension = {'*.cor', 'Molecule Coordinate File (*.COR)'};
    [filename pathname] = uigetfile(extension, 'Select a file to open', pref_dir);

    if filename == 0
        return;
    end

    [path name ext] = fileparts(filename);
    fullname = fullfile(pathname, filename);
	%fullname = '/home/xiaolin/Data/2009.03.17/BHK21_PSCFP2Tub_2.cor';
	
	params.fullname = fullname;			% this has to be before file loading
    load(fullname, '-MAT');				% this will create a few matrices including 'fullname' (that refers to original data file)
	params.filename = filename;
	params.pref_dir = pathname;

	% record a few other parameters
	params.frames = coords(1, 5);
	set(handles.dispframes, 'String', sprintf('%d', params.frames));
    set(handles.startframe, 'String', sprintf('%d', 1));
    set(handles.endframe, 'String', sprintf('%d', params.frames));

    
	params.width  = coords(1, 3) - coords(1, 1) + 1;
	params.height = coords(1, 4) - coords(1, 2) + 1;
	params.xoff   = coords(1, 1);
	params.yoff   = coords(1, 2);
	params.fiducials = fiducials;
	[r c] = size(coords);	
	params.coords = coords(2:r, :);

	% see if the file has a 'scf' matrix
	if exist('scf', 'var') == 1  && exist('sort_order', 'var') == 1
        params.is_sorted = 1;
		params.scf = scf;
		params.sort_order = sort_order;
		params.sortpars = sortpars;
		sort_nps = length(params.scf(:, 1));
		set(handles.dispsorted, 'String', sprintf('%d', sort_nps));
		set(handles.palmstats, 'enable', 'on');
		set(handles.renderpalm, 'enable', 'on');	
        set(handles.moviemode, 'enable', 'on', 'value', 0);
        set(handles.movieframe, 'enable', 'off');
        params.moviemode = 0;
        set(handles.timecumulative, 'enable', 'off', 'value', 0);
	else
		params.is_sorted = 0;
		params.scf = [];
		set(handles.renderpalm, 'enable', 'off');
		set(handles.dispsorted, 'String', 'n/a');
		set(handles.palmstats, 'enable', 'off');
        set(handles.moviemode, 'enable', 'off');
        set(handles.movieframe, 'enable', 'off');
        set(handles.timecumulative, 'enable', 'off', 'value', 0);
	end

    % generate the sum image (for display on the main panel)
	params.sumimg = zeros(params.height, params.width);
	ydims = ceil(params.coords(1:r-1, 3) - coords(1, 2) + 1);
	xdims = ceil(params.coords(1:r-1, 2) - coords(1, 1) + 1);
	for i = 1 : r-1
		params.sumimg(ydims(i), xdims(i)) = params.sumimg(ydims(i), xdims(i)) + 1;
	end

	% make sure fiducials do not appear as super-bright points in the low res image
	params.sumimg(find(params.sumimg > params.frames/60)) = params.frames/60;

	% frames, particle finding, and gaussian fitting
	raw_nps = length(params.coords(:, 1));
	set(handles.dispraw, 'String', sprintf('%d', raw_nps));
	
	if exist('pf_method', 'var')	% particle finding method
		set(handles.disppf, 'String', pf_method);
	else
		set(handles.disppf, 'String', 'SIT');
	end

	if exist('gf_method', 'var') % gaussian fitting method
		set(handles.dispfit, 'String', gf_method);
	else
		set(handles.dispfit, 'String', 'LSF');
	end
	
	% populate the 'sorted' structure variables
	if exist('sortpars', 'var')
		set(handles.pixelsize, 'String', sprintf('%d', sortpars.pixelsize));
		set(handles.comdist, 'String', sprintf('%.1f', sortpars.pdist));
		set(handles.thresh, 'String', sprintf('%.1f', sortpars.rms));
		set(handles.comframes, 'String', sprintf('%d', sortpars.preturn));
		set(handles.mingood, 'String', sprintf('%.2f', sortpars.goodness));
		set(handles.maxeccen, 'String', sprintf('%.1f', sortpars.eccentric));
	%else  % set the parameters to default
	%	set(handles.pixelsize, 'String', '140');
	%	set(handles.comdist, 'String', '140');
	%	set(handles.thresh, 'String', '4');
	%	set(handles.comframes, 'String', '15');
	%	set(handles.mingood, 'String', '0.25');
	%	set(handles.maxeccen, 'String', '1.6');
	end

	set(handles.palmsort, 'enable', 'on');
	set(handles.lowres, 'enable', 'off');
	set(handles.palmexport, 'enable', 'off');
	set(handles.rawstats, 'enable', 'on');
    set(handles.findfiducials, 'enable', 'on');
    set(handles.driftcorrect, 'enable', 'on');
	
	% enable or disable analysis tool buttons
	set(handles.pointtrack, 'enable', 'off');
	%set(handles.cluster, 'enable', 'off');
	
	% close off windows that associates with previous file
	onfigstatsclosed(0, 0);
	onfigfineclosed(0, 0);
	onfigpalmclosed(0, 0);
	
	% initialize status variables
	proc.fileopen = 1;
	
	% stop other processes if they are running
	if proc.cluster == 1
		stopcluster;
	end
	
	tmsg = sprintf('PALM File: %s', params.fullname);
	set(h_palmpanel, 'name', tmsg);
	showsumimage;
	dispmessage('File successfully loaded.');
	
	% all the variables stored; clear variables
	clear scf coords sort_order sortpars fiducials;	
end


