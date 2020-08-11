function newimg = imgbin(img, binsize)
% function that bins the input image (img)
[height width] = size(img);
nh = ceil(height/binsize);
nw = ceil(width/binsize);

newimg = zeros(nh, nw);

for i = 1 : nh
    for j = 1 : nw
        startx = (j - 1) * binsize + 1;
        endx = j * binsize;
        if endx > width
            endx = width;
        end
        
        starty = (i - 1) * binsize + 1;
        endy = i * binsize;
        if endy > height
            endy = height;
        end
        
        newimg(i, j) = mean(mean(img(starty:endy, startx:endx)));
    end
end