
function [IT1,IT2] = LVCTransformImagePair(I1, t1, I2, t2)

numRows = size(I1, 1);
numCols = size(I1, 2);
inPts = [1, 1; 1, numRows; numCols, numRows; numCols, 1];
tform = maketform('projective', t1);
outPts(1:4,:) = tformfwd(inPts, tform);
numRows = size(I2, 1);
numCols = size(I2, 2);
inPts = [1, 1; 1, numRows; numCols, numRows; numCols, 1];
tform = maketform('projective', t2);
outPts(5:8,:) = tformfwd(inPts, tform);

%--------------------------------------------------------------------------
% Compute the common rectangular area of the transformed images.
xSort = sort(outPts(:,1));
ySort = sort(outPts(:,2));
bbox(1) = ceil(xSort(4));
bbox(2) = ceil(ySort(4));
bbox(3) = floor(xSort(5)) - bbox(1) + 1;
bbox(4) = floor(ySort(5)) - bbox(2) + 1;

%--------------------------------------------------------------------------
% Generate a composite made by the common rectangular area of the
% transformed images.
htrans = vision.GeometricTransformer(...
  'TransformMatrixSource', 'Input port', ...
  'OutputImagePositionSource', 'Property', ...
  'OutputImagePosition', bbox);
IT1 = step(htrans, I1, t1);
IT2 = step(htrans, I2, t2);
% Iout(:,:,1) = IT1;
% Iout(:,:,2) = IT2;
% Iout(:,:,3) = IT2;
end

