function [binRim, binNorth, binSouth, binNorthNoRim, binSouthNoRim, numConMain, numConRim ] = extract_rim_spectral_clustering(T,P,varargin)
%function to extract the indices of the rim and separate the mesh into
%north and south hemispheres.
%Inputs:
%   T: surface mesh triangulation
%   P: surface mesh points (must correspond to unique(T))
%   varargin: 
%           nNeighbor: nNeighbor-ring neighborhood to use in spectral
%           clustering. Default: 4 
%           lambda: scaling parameter on spectral clustering weight.
%           Default: 20
%           rimDist: shortest-path distance (voxels) to grow rim width.
%           Default: 6
%           thresh: threshold for meancurvature extraction. default is 0.1
%Outputs:
%   binRim: indices corresponding to vertices in X that are labeled as rim.
%   binNorth: indices corresponding to vertices in X that are northern
%   hemishpere (computed by positive z-direction normal)
%   binSouth: same as binNorth, but southern hemisphere
%   Y: resulting smoothed points
%   numConMain: number of connected components in the main(non-rim)
%   placenta
%   numConRim: number of connected components in the rim
%   idxDil: 1 for nodes that exceed mean curvature threshold, 0 o.w.

nCluster = 2;
eigFunc = 2;
nNeighbor = 3;
rimDist = 5; %5 voxel neighborhood for rim
lambda = 20;

if( nargin == 3)
    nNeighbor = varargin{1};
elseif( nargin == 4)
    nNeighbor = varargin{1};
    lambda = varargin{2};
elseif( nargin == 5)
    nNeighbor = varargin{1};
    lambda = varargin{2};
    rimDist = varargin{3};
end

A = adjacency_matrix(T);
Ann = compute_knn_graph(A,nNeighbor);

%approximate geodesic distance between neighbors
D = compute_geodesic_distance_approximate(P,T,1:length(P));
D = D/max(D(find(Ann)));

%compute similarity metric
W = compute_mean_curvature_neighbors(P,Ann,T,lambda,D);
%cluster in 2 
IDX = spectral_cluster_maternal_fetal(W);
binNorthNoRim = find(IDX==1)';
binSouthNoRim = find(IDX==2)';
%find rim using closest neighbors based on (approximate) geodesic distance

%find the rim
IDX2 = find_rim_neighbor_distance(A,P,IDX,rimDist,T);
Arim = adjacency_matrix_per_label(A, IDX2,3);
Grim = graph(Arim);
binRim = conncomp(Grim);
numConRim = length(unique(binRim(IDX2==3)));

%check maximum connected component for fetal and maternal side... Can
%remove this later, just a sanity check.
Amain = adjacency_matrix_per_label(A, IDX2, 1);
Gmain = graph(Amain);
bin = conncomp(Gmain);
numConMain1 = length(unique(bin(IDX2==1))); %checks only 1 class. 
Amain = adjacency_matrix_per_label(A, IDX2, 2);
Gmain = graph(Amain);
bin = conncomp(Gmain);
numConMain2 = length(unique(bin(IDX2==2)));
numConMain = max(numConMain1, numConMain2);

%indices
%Note, these (except Rim) are ARBITRARY! Need to systematically assign
%north and south, with fetal/maternal sides!
binRim = find(IDX2==3)';
binNorth = find(IDX2==1)';
binSouth = find(IDX2==2)';
%trisurf(T,P(:,1),P(:,2),P(:,3),IDX2)

end

