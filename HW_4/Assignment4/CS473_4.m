
M = estimateCameraProjectionMatrix(impoints, objpoints3D);

[K, R, t] = getIntrinsicExtrinsicParams(M);





function M = estimateCameraProjectionMatrix(impoints2D, objpoints3D)
% ESTIMATECAMERAPROJECTIONMATRIX Estimate the camera projection matrix
%   given 2D image points and corresponding 3D object points.
%
%   M = ESTIMATECAMERAPROJECTIONMATRIX(impoints2D, objpoints3D) estimates
%   the camera projection matrix M using a least-squares method based on
%   the given 2D image points (impoints2D) and corresponding 3D object points
%   (objpoints3D).
%
%   Input arguments:
%       - impoints2D: an N-by-2 matrix representing N 2D image points.
%       - objpoints3D: an N-by-3 matrix representing N 3D object points.
%
%   Output argument:
%       - M: a 3-by-4 camera projection matrix that maps 3D object points to
%       2D image points.

    % Build the design matrix P
    N = size(impoints2D, 1);
    P = zeros(N*2, 12);
    for i = 1:N
        X = objpoints3D(i, :);
        x = impoints2D(i, :);
        P(2*i-1:2*i, :) = [
            X(1) X(2) X(3) 1 0 0 0 0 -x(1)*X(1) -x(1)*X(2) -x(1)*X(3) -x(1);
            0 0 0 0 X(1) X(2) X(3) 1 -x(2)*X(1) -x(2)*X(2) -x(2)*X(3) -x(2)
        ];
    end
    
    % Solve for M using a least-squares method
    [U, S, V] = svd(P, "econ");
    q = V(:, end); % This should take the last column V to create q
    M = reshape(q, [4, 3])'; 
    M = M ./ M(3, 4);
end

function [K, R, t] = getIntrinsicExtrinsicParams(M)
% Computes the intrinsic and extrinsic parameters from a camera projection
% matrix M using the method discussed in class.
%
% Inputs:
%   - M: camera projection matrix, in the form [K|R]
%
% Outputs:
%   - K: intrinsic parameters matrix
%   - R: rotation matrix of the object with respect to the camera
%   - t: translation vector of the object with respect to the camera
%
%% Calculating K
% Step 1.1: Calculate A and b
A = M(:,1:3);
b = M(:,4);

% Step 1.2: Calculate C = AA'
C = A*A';

% Step 1.3: Calculate lambda_sq
lambda_sq = 1/C(3,3);

% Step 1.4: Calculate Xc and Yc
Xc = lambda_sq*C(1,3);
Yc = lambda_sq*C(2,3);

% Step 1.4: Calculate Fy
Fy = sqrt((lambda_sq*C(2,2))-(Yc^2));

% Step 1.5: Calculate alpha
alpha = (1/Fy)*((lambda_sq*C(1,2)) - (Xc - Yc));

% Step 1.6: Calculate Fx
Fx = sqrt((lambda_sq*C(1,1))-(alpha^2)-(Xc^2));

% Step 1.7: Creating K matrix
K12 = (alpha*Fx)+(Xc*Yc);
K = [((Fx^2)+(alpha^2)+(Xc^2)) K12 Xc; K12 ((Fy^2)+(Yc^2)) Yc; Xc Yc 1]

%% Getting R
% Step 2: R = lambda * invK * A
lambda = 1 / sqrt(C(3,3));

R1 = lambda * inv(K) * A;
R2 = (-lambda) * inv(K) * A;

d1 = det(R1);
d2 = det(R2);

if(d1 > 0)
    R = R1
elseif(d2 > 0)
    R = R2
    lambda = -lambda
end
%% Getting t
% Step 3: t = lambda * invK * b
t = lambda * inv(K) * b

% t = t(:); % ensure t is a column vector
end