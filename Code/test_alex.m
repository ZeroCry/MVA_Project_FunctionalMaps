clear; clc;
init;
%%

alboptions.n_eigenvalues = 100; 
%%
%load shape 1
name = 'Data/shrec10/0003.null.0.off';
shape1.name = name;
[vertex,faces] = read_off(name);
vertex = vertex'; faces = faces';
shape1.vertex = vertex;
shape1.faces = faces;
%Compute ALB
[PHI,E,L,Am] = ALB_spectrum(vertex,faces,alboptions);
shape1.phi = PHI;
shape1.E = E;
shape1.Am = Am;
%Compute HKS
hks = HKS(PHI, E, diag(Am), false);
shape1.HKS = hks;
%Compute WKS
WKS = compute_WKS_from_EV(E,PHI,alboptions);
shape1.WKS = WKS;
clear WKS; clear hks;
clear PHI; clear E; clear L; clear Am;
clear vertex; clear faces; clear name;

%%
%load shape 2
name = 'Data/shrec10/0003.isometry.5.off';
shape2.name = name;
[vertex,faces] = read_off(name);
vertex = vertex'; faces = faces';
shape2.vertex = vertex;
shape2.faces = faces;
[PHI,E,L,Am] = ALB_spectrum(vertex,faces,alboptions);
shape2.phi = PHI;
shape2.E = E;
shape2.Am = Am;
%Compute HKS
hks = HKS(PHI, E, diag(Am), false);
shape2.HKS = hks;
%Compute WKS
WKS = compute_WKS_from_EV(E,PHI,alboptions);
shape2.WKS = WKS;
clear WKS; clear hks;
clear PHI; clear E; clear L; clear Am;
clear vertex; clear faces; clear name;

%%
% Add constraint to linear system
a1 = shape1.phi'*shape1.Am*shape1.HKS;
a2 = shape1.phi'*shape1.Am*shape1.WKS;
a = [a1 a2];

b1 = shape2.phi'*shape2.Am*shape2.HKS;
b2 = shape2.phi'*shape1.Am*shape2.WKS;
b = [b1 b2];

C = b/a;
%%
%Build KD-tree
tree1 = kdtree_build(shape1.phi);
tree2 = kdtree_build(shape2.phi);

%%
clear options
colors = zeros(19248,1);
colors(1:1000,1) = 2;
options.face_vertex_color = colors
plot_mesh(shape1.vertex,shape1.faces,options);
shading interp; colormap jet(256);

%%
%Search for 100 first vertex and set colors 
clear options2;
color = zeros(19248,1);
for i = 1:1000
    p1 = shape1.phi(i,:)';
    nn = kdtree_k_nearest_neighbors(tree2,C*p1,1);
    [fi,fj] = find(shape2.faces==nn);
    color(shape2.faces(fi,1)) = 2;
    color(shape2.faces(fi,2)) = 2;
    color(shape2.faces(fi,3)) = 2;
end
options2.face_vertex_color = color;
plot_mesh(shape2.vertex,shape2.faces,options2);
shading interp; colormap jet(256);

%%
%Refinement of C
clc
C0 = C;
%%

C0P1 = (C0*shape1.phi')';
s = 0;
for i = 1:19248
    pSearch = C0P1(i,:);
    nn = kdtree_k_nearest_neighbors(tree2,pSearch,1);
    nnVal = shape2.phi(nn,:);
    s=s+norm(pSearch-nnVal);
end

%%
%Test with own function

shape1.projectedHKS = shape1.phi(:,2:end)'*shape1.Am*shape1.HKS(:,5);
%%


shape1.reconstructedWKS = zeros(19248,1);

for i = 1:99
    shape1.reconstructedWKS = shape1.reconstructedWKS + shape1.projectedHKS(i)*shape1.phi(:,i+1);
    if (mod(i,9)==0)
        figure(1);
        clf
        options.face_vertex_color = shape1.reconstructedWKS;
        plot_mesh(shape1.vertex,shape1.faces,options);
        shading interp; colormap jet(256);
        pause();
        
        sum(sum(shape1.reconstructedWKS))
    end
end
%%

figure(1);
options.face_vertex_color = shape1.WKS(:,5);
plot_mesh(shape1.vertex,shape1.faces,options);
shading interp; colormap jet(256);