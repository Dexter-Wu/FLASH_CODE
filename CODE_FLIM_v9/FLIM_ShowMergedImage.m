function FLIM_ShowMergedImage(I_descattering, Lifetime_Img, Intensity_Map, R_square_Img, R_square_thre, inten_reso, life_reso)

% FLIM_ShowMergedImageV2 - Display lifetime, R², intensity, and merged maps
%
% Usage:
%   FLIM_ShowMergedImageV2(I_descattering, Lifetime_Img, Intensity_Map, ...
%                         R_square_Img, R_square_thre, inten_reso, life_reso)
%
% Inputs:
%   I_descattering  - 2D intensity image after descattering
%   Lifetime_Img    - 2D lifetime image (in seconds, converted internally to microseconds)
%   Intensity_Map   - 2D raw intensity map
%   R_square_Img    - 2D R² goodness-of-fit map
%   R_square_thre   - Threshold applied to R² for masking lifetime values
%   inten_reso      - Resolution of intensity dimension in LUT
%   life_reso       - Resolution of lifetime dimension in LUT
%
% Notes:
%   - Lifetime values are masked by R² threshold before visualization.
%   - Intensity is enhanced by weighting with R².
%   - A 2D LUT is constructed to encode lifetime (color) and intensity (brightness).
%   - Each subplot includes a colorbar with min/max annotations.
%   - Colormaps: Lifetime → rainbow (slanCM), Intensity → gray, Merged → custom LUT.

%% Apply R² threshold only to Lifetime
Lifetime_temp = Lifetime_Img*1e6; % convert to us
mask = R_square_Img > R_square_thre;
Lifetime_masked = zeros(size(Lifetime_temp));
Lifetime_masked(mask) = Lifetime_temp(mask);
R_square_Img(R_square_Img<0)  = 0;

%  
lifetime_max = 1200;
Lifetime_masked(Lifetime_masked>lifetime_max) =  lifetime_max;

% lifetime_max = max(Lifetime_masked(:))

%% Intensity map is full range (0~1)
% Intensity_masked = double(I_enhancement);
I_enhancement = double(I_descattering).*R_square_Img;
% Normalize for merge
Lifetime_norm = Lifetime_masked / lifetime_max;
Enhanced_norm = I_enhancement/ max(I_enhancement(:)); 


%% 2. Lifetime-Intesity LUT 
% cmap = autumn(life_reso);
cmap = slanCM('wistia');
% cmap = cmap(life_reso);
cmap = reshape(cmap, 1, size(cmap,1),3);
for i = 1:inten_reso-1
    cmap = [cmap; cmap(1,:,:) * (inten_reso-i)/inten_reso];
end
cmap = flipud(cmap);

[r,c] = size(Lifetime_norm);
Merge = zeros(r,c,3);
for i = 1:r
    for j = 1:c
        inten_idx = round(Enhanced_norm(i,j)*(inten_reso-1))+1;
        life_idx  = round(Lifetime_norm(i,j)*(life_reso-1))+1;
        inten_idx = max(1,min(inten_idx,inten_reso));
        life_idx  = max(1,min(life_idx,life_reso));
        Merge(i,j,:) = cmap(inten_idx, life_idx,:);
    end
end

%% 3. Figure Para
figure('Color','w','Position',[100 100 2000 450]);
gap = 0.005; cb_w = 0.02; img_w = 0.20; img_h = 0.8; bottom = 0.1;

%% ------------------- 2. Raw_Img -------------------
Raw_Img = double(Intensity_Map);
axR2 = axes('Position',[0.05 bottom img_w img_h]);
imagesc(Raw_Img); axis image off;
colormap(axR2, gray);
clim([min(Raw_Img(:)), max(Raw_Img(:))]);
title('$\hat{I}_{0}$ Intensity Map','Interpreter','latex','FontSize',16);

axR2_cb = axes('Position',[0.05+img_w+gap bottom cb_w img_h]);
imagesc(flipud(repmat(linspace(min(Raw_Img(:)), max(Raw_Img(:)), 256),256,1)')); 
axis off; colormap(axR2_cb, gray);
hold(axR2_cb,'on');
text(1,1,sprintf('%d', round(max(Raw_Img(:)))),'Parent',axR2_cb,...
    'HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',16);
text(1,256,sprintf('%d', round(min(Raw_Img(:)))),'Parent',axR2_cb,...
    'HorizontalAlignment','left','VerticalAlignment','top','FontSize',16);
hold(axR2_cb,'off');

%% ------------------- 2. Intensity -------------------
ax2 = axes('Position',[0.05+img_w+cb_w+2*gap bottom img_w img_h]);
I_descattering = double(I_descattering);
imagesc(I_descattering); axis image off;
colormap(ax2,gray);
clim([min(I_descattering(:)), max(I_descattering(:))]);
title('$\hat{I}_{\rm des}$','Interpreter','latex','FontSize',16);

ax2_cb = axes('Position',[0.05+2*img_w+cb_w+3*gap bottom cb_w img_h]);
imagesc(flipud(repmat(linspace(min(I_descattering(:)), max(I_descattering(:)), 256),256,1)')); 
axis off; colormap(ax2_cb,gray);
hold(ax2_cb,'on');
text(1+100,1,sprintf('%d', round(max(I_descattering(:)))),'Parent',ax2_cb,...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FontSize',16);
text(1+100,256,sprintf('%d', round(min(I_descattering(:)))),'Parent',ax2_cb,...
    'HorizontalAlignment','center','VerticalAlignment','top','FontSize',16);
hold(ax2_cb,'off');

%% ------------------- 3. Intensity -------------------
ax1 = axes('Position',[0.05+2*img_w+2*cb_w+4*gap bottom img_w img_h]);
imagesc(I_enhancement); axis image off;
colormap(ax1,gray);
clim([min(I_enhancement(:)), max(I_enhancement(:))]);
title('$\hat{I}_{\rm enh}$','Interpreter','latex','FontSize',16);

ax1_cb = axes('Position',[0.05+3*img_w+2*cb_w+5*gap bottom cb_w img_h]);
imagesc(flipud(repmat(linspace(min(I_enhancement(:)), max(I_enhancement(:)), 256),256,1)')); 
axis off; colormap(ax1_cb,gray);
hold(ax1_cb,'on');
text(1,1,sprintf('%d', round(max(I_enhancement(:)))),'Parent',ax1_cb,...
    'HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',16);
text(1+100,256,sprintf('%d', round(min(I_enhancement(:)))),'Parent',ax1_cb,...
    'HorizontalAlignment','center','VerticalAlignment','top','FontSize',16);
hold(ax1_cb,'off');

%% ------------------- 4. Merge -------------------
ax3 = axes('Position',[0.05+3*img_w+3*cb_w+6*gap bottom img_w img_h]);
imagesc(Merge); axis image off; 
title('Lifetime/Intensity Map','Interpreter','latex','FontSize',14);

ax3_cb = axes('Position',[0.05+4*img_w+3*cb_w+7*gap bottom cb_w img_h]);
merge_cb_img = zeros(life_reso,inten_reso,3);
for i = 1:inten_reso
    for j = 1:life_reso
        merge_cb_img(j,i,:) = cmap(i,j,:);
    end
end
merge_cb_img = flipud(merge_cb_img); 
imagesc(merge_cb_img); axis off;

hold(ax3_cb,'on');
text(inten_reso-200,280,'0','Parent',ax3_cb,...
    'HorizontalAlignment','right','VerticalAlignment','bottom','FontSize',16);
text(inten_reso,280,'1','Parent',ax3_cb,...
    'HorizontalAlignment','right','VerticalAlignment','bottom','FontSize',16);
text(inten_reso+10,260,sprintf('%d', round(min(Lifetime_masked(:)))),'Parent',ax3_cb,...
    'HorizontalAlignment','left','VerticalAlignment','bottom','FontSize',16);
text(inten_reso+10,1,sprintf('%d', round(lifetime_max)),'Parent',ax3_cb,...
    'HorizontalAlignment','left','VerticalAlignment','top','FontSize',16);
hold(ax3_cb,'off');

end
