function img = gauss2d(b, a, x0, y0, sig, w, h)
% This function generates a 2d gaussian image based on parameters given
lowx = ceil(x0 - w/2);   highx = lowx + w - 1;
lowy = ceil(y0 - h/2);   highy = lowy + h - 1;

[x y] = meshgrid(lowx:highx, lowy:highy);

img = b + a * exp(-(double(x - x0).^2 + double(y - y0).^2)/(2*sig^2));
