function d = dist(x1,y1,x2,y2)
% function that calculates the distance between two points (x1, y1) and (x2, y2)
% usage:
%  d = dist(x1, y1, x2, y2)
% 

d = sqrt((x1-x2) .^ 2 + (y1-y2) .^2);
