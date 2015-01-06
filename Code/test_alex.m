clear; 
clc;
init;

name1 = 'Data/shrec10/0003.null.0.off';
name2 = 'Data/shrec10/0003.isometry.4.off';
%%Avec la 4 c'est top horse
%%Avec la 5 c'est top horse
%%Avec la 2 c'est top dog

shape1 = getShape(name1);
shape2 = getShape(name2);

%%

C1 = persistance_based_segmentation(shape1,7);
shape1.connected_component = C1;
list_label_C1 = union(C1,C1);


C2 = persistance_based_segmentation(shape2,7);
shape2.connected_component = C2;
list_label_C2 = union(C2,C2);

list_matching = [];

list_descriptors_C1 = compute_descriptors_for_matching(shape1);
list_descriptors_C2 = compute_descriptors_for_matching(shape2);


%[~,perm1] = sort(list_descriptors_C1);
%[~,perm2] = sort(list_descriptors_C2);
nb_comp_C1 = size(list_label_C1,1);
nb_comp_C2 = size(list_label_C2,1);

err=[];
for i=1:nb_comp_C1
    for j=1:nb_comp_C2
        err(i,j) = (list_descriptors_C1(i) - list_descriptors_C2(j))^2./(list_descriptors_C1(i) + list_descriptors_C2(j));
    end
end
i = 0;
INFTY = max(max(err))+1;
while(i~=min(nb_comp_C1,nb_comp_C2))
    i = i+1;
    [min_per_col,idx_row] = min(err);
    [diff,idx_col] = min(min_per_col);
    list_matching(i,:) = [ list_label_C1(idx_row(idx_col)) list_label_C2(idx_col) diff ];
    
    % Replace idx_row(idx_col)th row and idx_colth col of err with a high
    % value
    err(idx_row(idx_col),:) = INFTY;
    err(:,idx_col) = INFTY;
end

%Plot mesh with color correspondence to same segment
% figure(1);
% options.face_vertex_color = compute_color_from_connected_component(C1, list_matching(:,1));
% plot_mesh(shape1.vertex,shape1.faces,options);
% shading interp; colormap jet(256);
% 
% figure(2);
% options.face_vertex_color = compute_color_from_connected_component(C2, list_matching(:,2));
% plot_mesh(shape2.vertex,shape2.faces,options);
% shading interp; colormap jet(256);

%%
clc
shape1.indicComp(:,1) = 1.*(C1==11369);
shape2.indicComp(:,1) = 1.*(C2==15086);




clc
nbIndicomp = 1;
for i = 1:size(list_matching,1)
        shape1.indicCompNOCONSTRAINTS(:,nbIndicomp) = 1.*(C1==list_matching(i,1));
        shape2.indicCompNOCONSTRAINTS(:,nbIndicomp) = 1.*(C2==list_matching(i,2));
        nbIndicomp = nbIndicomp +1
end

%%
[C] = getFunctionalMap(shape1,shape2);
%%
image(C,'CDataMapping','scaled');
%%
HKS2_2 = shape2.phi*(shape2.phi'*shape2.Am*shape2.HKS(:,1));
HKS1_2 = shape2.phi*C*shape1.phi'*shape1.Am*shape1.HKS(:,1);

option.face_vertex_color = HKS2_2;
plot_mesh(shape2.vertex,shape2.faces,option);
shading interp; 
colormap jet;

figure();
option.face_vertex_color = HKS1_2;
plot_mesh(shape2.vertex,shape2.faces,option);
shading interp; 
colormap jet;



%%
%Test KD-tree
shape1.tree = kdtree_build(shape1.phi);
shape2.tree = kdtree_build(shape2.phi);

%
clear options
colors = zeros(19248,1);
colors(16000:17000,1) = 2;
options.face_vertex_color = colors
plot_mesh(shape1.vertex,shape1.faces,options);
shading interp; colormap jet(256);

%Search for 100 first vertex and set colors 
clear options2;

%%
figure();
options2.face_vertex_color = zeros(19248,1);
plot_mesh(shape2.vertex,shape2.faces,options2);
colormap jet(256);
hold on

%%
clear v1 v2 v3;
phi_t = shape2.phi;
for i = 1:19248
    tic
    tree = kdtree_build(phi_t);
    if(mod(i,100)==0)
        i
        size(phi_t);
    end
    i
    size(phi_t)
    p1 = shape1.phi(i,:)';
    nn = kdtree_k_nearest_neighbors(tree,C*p1,1);
    phi_t(nn,:) = [];
    v1(i) = shape2.vertex(nn,1);
    v2(i) = shape2.vertex(nn,2);
    v3(i) = shape2.vertex(nn,3);
    kdtree_delete(tree);
    toc
   
end
%%
 plot3(v1,v2,v3,'ro');

zax = get(gca,'ZLim');
axis equal
set(gca,'Zlim',zax)

%%
s = 19248
plot3(shape1.vertex(1:s,1),shape1.vertex(1:s,3),shape1.vertex(1:s,2),'or')



%%
%How many eigenfunctions are needed
%Based on the idea of
%http://alice.loria.fr/publications/papers/2006/SMI_Laplacian/SMI_Laplacian.pdf
%to reconstruct functions based on projections
%
% 1. Project function on the eigenfunctions of the LB operator
% 2. Reconstruct function based on first eigenvalues
% 3. Take the sum of the function to see how it converges
func = shape1.WKS(:,5)
shape1.projectedFunction = shape1.phi'*shape1.Am*func;
shape1.reconstructedFunction = zeros(19248,1);

s = [];
for i = 1:100
    shape1.reconstructedFunction = shape1.reconstructedFunction + shape1.projectedFunction(i)*shape1.phi(:,i);
    s = [s sum(sum(shape1.reconstructedFunction))/19248];
    figure(1);
    clf
    options.face_vertex_color = shape1.reconstructedFunction;
    plot_mesh(shape1.vertex,shape1.faces,options);
    shading interp; colormap jet(256);
    pause(0.1);
end
plot(s);
hold on
plot(repmat(sum(sum(func))/19248,1,100),'r')
%%
figure(1);
options.face_vertex_color = shape1.HKS(:,2);
plot_mesh(shape1.vertex,shape1.faces,options);
shading interp; colormap jet(256);

%%
% Post processing iterative refinement
tree2 = kdtree_build(shape2.phi);
C = eye(100,100);

C_iteration = C;

for iteration = 1:1000
    CPHI_M = C_iteration*shape1.phi';
    correspondences = zeros(19248,1);
    for i = 1:19248
        if(mod(i,100)==0)
            i
        end
        [idx] = kdtree_k_nearest_neighbors(tree2,CPHI_M(:,i),1);
        correspondences(i) = idx;
    end
    e = CPHI_M - shape2.phi(correspondences,:);
    sum(sum(e))
end

%%

for i = 1:100    
    subplot(2,1,2)
    plot(C*shape1.phi'*shape1.Am*shape1.WKS(:,i)); 
    hold on; 
    plot(shape2.phi'*shape2.Am*shape2.WKS(:,i),'ro')
    ylim([-1,1]);
    hold off;
    pause(0.1);
end
%%

figure(1)
fun = shape1.indicCompNOCONSTRAINTS(:,7);
option.face_vertex_color = fun;
plot_mesh(shape1.vertex, shape1.faces, option);
shading interp;
colormap jet;

fun12 = shape2.phi*(C*(shape1.phi'*shape1.Am*fun));

[sortedValues,sortIndex] = sort(fun12(:),'descend');
fun12(sortIndex(1:sum(fun))) = 1;
fun12(sortIndex(sum(fun)+1:end)) =0;

%%
figure(2);
option2.face_vertex_color = fun12;
plot_mesh(shape2.vertex, shape2.faces, option2);
shading interp;
colormap jet;

%%
fun = shape1.HKS(:,1);
option.face_vertex_color = fun;
plot_mesh(shape1.vertex, shape1.faces, option);
shading interp;
colormap jet;

%%
% Test corresponding segment

%15346
%11369
%4833

gt4 = load('Data\shrec10gt\0003.isometry.4.labels');

shape1.parts = [];
shape2.parts = [];

shape1.parts = [shape1.parts 1.*(C1==15346)];
shape2.parts = [shape2.parts getAssociatedSegmentFromNull(1.*(C1==15346),gt4)];
shape1.parts = [shape1.parts 1.*(C1==11369)];
shape2.parts = [shape2.parts getAssociatedSegmentFromNull(1.*(C1==11369),gt4)];
shape1.parts = [shape1.parts 1.*(C1==4833)];
shape2.parts = [shape2.parts getAssociatedSegmentFromNull(1.*(C1==4833),gt4)];



% figure();
% subplot(1,2,1);
% options1.face_vertex_color = segmentNull;
% plot_mesh(shape1.vertex,shape1.faces,options1);
% subplot(1,2,2);
% options2.face_vertex_color = segment4;
% plot_mesh(shape2.vertex,shape2.faces,options2);

clear shape1.fun_segment;
clear shape2.fun_segment;

shape1.fun_segment = [];
shape2.fun_segment = [];

for i = 1:size(shape1.WKS,2)
    shape1.fun_segment = [shape1.fun_segment repmat(shape1.WKS(:,i),1,size(shape1.parts,2)) .* shape1.parts];
end
for i = 1:size(shape1.HKS,2)
    shape1.fun_segment = [shape1.fun_segment repmat(shape1.HKS(:,i),1,size(shape1.parts,2)) .* shape1.parts];
end
for i = 1:size(shape2.WKS,2)
    shape2.fun_segment = [shape2.fun_segment repmat(shape2.WKS(:,i),1,size(shape2.parts,2)) .* shape2.parts];
end
for i = 1:size(shape2.HKS,2)
    shape2.fun_segment = [shape2.fun_segment repmat(shape2.HKS(:,i),1,size(shape2.parts,2)) .* shape2.parts];
end

shape1.fun = [shape1.fun_segment, shape1.HKS, shape1.WKS];
shape2.fun = [shape2.fun_segment, shape2.HKS, shape2.WKS];


disp('Computing C');

C = calcCFromFuncs(shape1.fun,shape2.fun,shape1.phi,shape2.phi,shape1.L,shape2.L);
disp('Done');
%Create functions to use

%%
searchIndexParams = struct();
shape2toshape1 = flann_search(shape1.phi', C'*shape2.phi', 1, searchIndexParams);

%%
plot_mesh(shape1.vertex,shape1.faces);
for i = 1:19248
    hold on
    plot3([shape1.vertex(shape2toshape1(i),1),shape1.vertex(gt4(i),1)],[shape1.vertex(shape2toshape1(i),2) shape1.vertex(gt4(i),2)],[shape1.vertex(shape2toshape1(i),3) shape1.vertex(gt4(i),3)],'r');
    hold off
   
end