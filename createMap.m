% KEYMAP FUNCTION

function [B, map] = createMap(video)

close all

vid = VideoReader(fullfile('videos',video));

f = readFrame(vid);
g = rgb2gray(f);
g = im2bw(g, 1.4*graythresh(g));
% imshow(g)

%% PROCESSING THE IMAGE

% remove fine details
g = imopen(imclose(g,ones(3,2)),ones(3,2));
% remove reflective edges on black keys
g = imopen(g,ones(150,1));

% isolation of keys via horizontal edges
hbounds = sum(edge(double(g), 'canny', 'horizontal'), 2);
hbins = zeros(vid.Height/5,1);
for i = 1:vid.Height/5
    hbins(i) = sum(hbounds(5*i-4:5*i));
end
[temp, pos] = sort(hbins(1:size(hbins)-1), 'descend');
p = pos(1:2);

% edge detection, invert, fill keys, remove background
g  = imcomplement(edge(double(g), 'canny'));
g = imopen(g,ones(20));
g = imerode(g,ones(2));
g(1:min(p)*5,:) = 0;
g(max(p)*5-10:vid.Height,:) = 0;

% figure
% imshow(g)

%% FINDING THE BOUNDARIES & MAPPING NOTE NAMES

[B, L, N, A] = bwboundaries(g, 'noholes');
map = cellstr(num2str(zeros(N, 1)));
names = cellstr(['B ';'Bb';'A ';'Ab';'G ';'Gb';'F ';'E ';'Eb';'D ';'Db';'C ']);

% find key where the keys 2, 4, and 6 spaces away are all black. this is C.
for i = 1:N-6
    key = numel(B{i});
    if key > 1.3*numel(B{i+2}) && key > 1.3*numel(B{i+4}) && key > 1.3*numel(B{i+6})
        break;
    end
end

% if this C key is sufficiently far left, probably a C5, otherwise C4
if i < 6
    octave = 5;
else
    octave = 4;
end

% now map everything else to the left and right of this C.
for j = 1:i
    map(j) = strcat(names(12-(i-j)),num2str(octave));
end
octave = octave - 1; % down 1 octave to right of C
k = 1;
for j = i+1:N
    map(j) = strcat(names(k),num2str(octave));
    k = k + 1;
    if k == 13
        k = 1;
        octave = octave - 1;
    end
end

figure % show keymap
imshow(f)
hold on;
for i = 1:N
    b = B{i};
    plot(b(:,2),b(:,1),'g','Linewidth',2);
    col = b(1,2); row = b(1,1);
    h = text(col+10, row+10, map(i));
    set(h,'Color','g','FontSize',14,'FontWeight','bold');
end