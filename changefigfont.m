function changefigfont()
%
% function changefigfont(figface)
% this is to facilitate the figure output for publication use
% 

	
	% define the default set of font faces
	XL_FONT = 'Arial';
	XL_SIZE = 18;
	XL_FACE = 'normal';
	
	YL_FONT = 'Arial';
	YL_SIZE = 18;
	YL_FACE = 'normal';
	
	T_FONT = 'Arial';
	T_SIZE = 14;
	T_FACE = 'normal';
	
	
	ax = get(gcf, 'CurrentAxes');
	
	% change xlabel font
	xl = get(ax, 'XLabel');
	set(xl, 'FontName', XL_FONT, 'FontSize', XL_SIZE, 'FontWeight', XL_FACE);
	
	yl = get(ax, 'YLabel');
	set(yl, 'FontName', YL_FONT, 'FontSize', YL_SIZE, 'FontWeight', YL_FACE);
	
	set(ax, 'FontName', T_FONT, 'FontSize', 14);

