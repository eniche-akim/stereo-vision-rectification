
%%%%%%%%%%%%%%% rectification d'une paire d'image %%%%%%%%%%%%%%%%%%%%%


%% Step 1: Read Stereo Image Pair

    I1 = im2double(rgb2gray(imread('R.jpg')));
    I2 = im2double(rgb2gray(imread('L.jpg')));

% visualisation des images
close all;
figure; imshow([I1 I2]);
title('les deux images originale avant rectification');

%% Step 2: Collectez des points d'intérêt à partir de chaque image
    blobs1 = detectSURFFeatures(I1, 'MetricThreshold', 2000);
    blobs2 = detectSURFFeatures(I2, 'MetricThreshold', 2000);    
    
 %% Step 3: recherches des points de correspondances
 
  disp('Utilisez les fonctions extractFeatures et matchFeatures pour trouver') 
  disp('des correspondances de points putatives. Pour chaque goutte,')
  disp('calculez les vecteurs de caractéristiques SURF (descripteurs).')
    [features1, validBlobs1] = extractFeatures(I1, blobs1);
    [features2, validBlobs2] = extractFeatures(I2, blobs2);
    
     %Utilisez la somme des différences absolues (TAS) pour déterminer les indices des caractéristiques 
     %d'appariement.
    indexPairs = matchFeatures(features1, features2, 'Metric', 'SAD', ...
        'MatchThreshold', 5);
    
    % Récupérer l'emplacement des points correspondants pour chaque image
    matchedPoints1 = validBlobs1.Location(indexPairs(:,1),:);
    matchedPoints2 = validBlobs2.Location(indexPairs(:,2),:);
    

figure; imshow([I1 I2]);
title('les Points de correspondance issuent  de la fonction SURF');

hold on
for pt=1:size(matchedPoints1)
    line([matchedPoints1(pt,1),matchedPoints2(pt,1)+size(I1,2)],[matchedPoints1(pt,2),matchedPoints2(pt,2)],'Color','g');
    plot(matchedPoints1(pt,1),matchedPoints1(pt,2),'r+');    
    plot(matchedPoints2(pt,1)+size(I1,2),matchedPoints2(pt,2),'b+');
end

%% Step 4: Supprimer les valeurs aberrantes à l'aide de la contrainte épipolaire

disp('Les points correctement appariés doivent satisfaire aux contraintes épipolaires.') 
disp('Cela signifie que un point doit se trouver sur la ligne épipolaire déterminée par son point')
disp('correspondant. Vous utiliserez la fonction estimateFundamentalMatrix pour') 
disp('calculer la matrice fondamentale et trouver les inliers qui répondent à la contrainte épipolaire.')

[fMatrix, epipolarInliers, status] = estimateFundamentalMatrix(...
  matchedPoints1, matchedPoints2, 'Method', 'RANSAC', ...
  'NumTrials', 10000, 'DistanceThreshold', 0.1, 'Confidence', 99.99);
  draw_epipolar( fMatrix, I1, I2, matchedPoints1, matchedPoints2);

if status ~= 0 || isEpipoleInImage(fMatrix, size(I1)) ...
  || isEpipoleInImage(fMatrix', size(I2))
  error(['pour que la rectification se fait correctemment, les images doivent avoir suffisamnent '...
    'de points decorrespondndance et les epipoles doivent etre en dehors les images.']);
end

inlierPoints1 = matchedPoints1(epipolarInliers, :);
inlierPoints2 = matchedPoints2(epipolarInliers, :);
figure(3); imshow([I1 I2]);
hold on

for pt=1:size(inlierPoints1)
    line([inlierPoints1(pt,1),inlierPoints2(pt,1)+size(I1,2)],[inlierPoints1(pt,2),inlierPoints2(pt,2)],'Color','y');
    plot(inlierPoints1(pt,1),inlierPoints1(pt,2),'r+');    
    plot(inlierPoints2(pt,1)+size(I1,2),inlierPoints2(pt,2),'b+');
end
title('Point Correspondences after filtering outliers')
hold on

%% Step 5: Rectifications des Images

disp('Utilisez la fonction estimateUncalibratedRectification pour calculer les transformations') 
disp('de rectification. Ceux-ci peuvent être utilisés pour transformer les images,') 
disp('de sorte que les points correspondants apparaissent sur les mêmes lignes.')

[t1, t2] = estimateUncalibratedRectification(fMatrix, ...
  inlierPoints1, inlierPoints2, size(I2));

% Recadrez la zone de chevauchement des images rectifiées. 
[IRet1,IRet2] = LVCTransformImagePair(I1, t1, I2, t2);

figure
subplot(1,2,1);
imshow(IRet1);
title('image droite rectifieé');
subplot(1,2,2);
imshow(I1);
title('image droite originale');
figure
subplot(1,2,1);
imshow(IRet2);
title('image gauche rectifiée');
subplot(1,2,2);
imshow(I2)
title('image gauche originale');
fMatrix = zeros(3,3);
fMatrix(2,3) = -1; fMatrix(3,2) = 1;
draw_epipolar( fMatrix, IRet1, IRet2, matchedPoints1, matchedPoints2);

