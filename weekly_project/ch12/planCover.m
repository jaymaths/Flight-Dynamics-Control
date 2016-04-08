%% planRRT
%%  - basic coverage algorithm
%%  
%% Last Modified - 11/15/2010 - R. Beard

function path=planCover(wpp_start, map, R_min)
    
    % desired down position is down position of start node
    pd = wpp_start(3);
    
    % specify start node from wpp_start 
    start_node = [wpp_start(1), wpp_start(2), pd, wpp_start(4), 0, 0];
    % format is [N, E, D, chi, cost, parent]
 
 
    % return map
    returnMapSize = 30;  % this is a critical parameter!
    return_map = 50*ones(returnMapSize,returnMapSize)+ rand(returnMapSize,returnMapSize);
    plotReturnMap(return_map), %pause

    % construct search path by doing N search cycles
    SEARCH_CYCLES = 50;  % number of search cycles
       
    % look ahead tree parameters
    L = 2.2*R_min;  % segment Length
    vartheta = pi/4; % search angle
    depth = 5; % depth of look ahead tree
    
    % initialize path and tree
    path = start_node;
    for i=1:SEARCH_CYCLES,
        tree = extendTree(path(end,:),L,vartheta,depth,map,return_map,pd);
        next_path = findMaxReturnPath(tree);
        path = [path; next_path(1,:)];
        % update the return map
        return_map = updateReturnMap(next_path(1,:),return_map,map);
        plotReturnMap(return_map), %pause 
        % set the end of the path as the root of the tree
    end
    
    % remove path segments where there is no turn
    path_=path;
    path = path(1,:);
    for i=2:size(path_,1),
        if path_(i,4)~=path_(i-1,4);
            path = [path; path_(i,:)];
        end
    end
        
    % specify that these are straight-line paths.
    for i=1:size(path,1),
        path(i,4)=-9999; 
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% extendTree
%%   extend tree by randomly selecting point and growing tree toward that
%%   point
function tree = extendTree(start_node,L,vartheta,depth,map,return_map,pd)

  tree_ = [start_node, 0];  % the last variable marks node as expanded

  % extend tree initially
  for d = 1:depth,
      newnodes = [];
      for j=1:size(tree_,1),
          if tree_(j,7)~=1, % process unexpanded nodes
              for i=1:3,
                  if     i==1, theta = tree_(j,4)-vartheta;
                  elseif i==2, theta = tree_(j,4);
                  elseif i==3, theta = tree_(j,4)+vartheta;
                  end
                  newnode_ = [...
                      tree_(j,1)+L*cos(theta),...
                      tree_(j,2)+L*sin(theta),...
                      tree_(j,3),...
                      theta,...
                      0,...
                      j,...
                      0,...
                      ];
                  if collision(tree_(j,:), newnode_, map)==0,
                      newnode_(5) = tree_(j,5)...
                          +findReturn(newnode_(1),newnode_(2),return_map,map);
                      newnodes = [newnodes; newnode_];
                  end
              end
              tree_(j,7)=1; % mark as expanded
          end
      end
      tree_ = [tree_; newnodes];
  end
  tree = tree_(:,1:6);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% collision
%%   check to see if a node is in collsion with obstacles
function collision_flag = collision(dubinspath, pd, map)

    collision_flag = 0;
    
    [X,Y] = pointsAlongDubinsPath(dubinspath,0.1);
    for i = 1:length(X),
        if pd >= downAtNE(map, X(i), Y(i)),
            collision_flag = 1;
        end
    end
    
    % check to see if outside of world
    if (max(X)>map.width) || (min(X)<0) || (max(Y)>map.width) || (min(Y)<0),
        collision_flag = 1;
    end
end

% Find Points Along Dubins Path
function [X,Y] = pointsAlongDubinsPath(dubinspath,Del)


  % points along start circle
  th1 = mod(atan2(dubinspath.ps(2)-dubinspath.cs(2),dubinspath.ps(1)-dubinspath.cs(1)),2*pi);
  th2 = mod(atan2(dubinspath.w1(2)-dubinspath.cs(2),dubinspath.w1(1)-dubinspath.cs(1)),2*pi);
  if dubinspath.lams>0,
      if th1>=th2,
        th = [th1:Del:2*pi,0:Del:th2];
      else
        th = [th1:Del:th2];
      end
  else
      if th1<=th2,
        th = [th1:-Del:0,2*pi:-Del:th2];
      else
        th = [th1:-Del:th2];
      end
  end
  X = [];
  Y = [];
  for i=1:length(th),
    X = [X; dubinspath.cs(1)+dubinspath.R*cos(th(i))]; 
    Y = [Y; dubinspath.cs(2)+dubinspath.R*sin(th(i))];
  end
  
  % points along straight line 
  sig = 0;
  while sig<=1,
      X = [X; (1-sig)*dubinspath.w1(1) + sig*dubinspath.w2(1)];
      Y = [Y; (1-sig)*dubinspath.w1(2) + sig*dubinspath.w2(2)];
      sig = sig + Del;
  end
    
  % points along end circle
  th2 = mod(atan2(dubinspath.pe(2)-dubinspath.ce(2),dubinspath.pe(1)-dubinspath.ce(1)),2*pi);
  th1 = mod(atan2(dubinspath.w2(2)-dubinspath.ce(2),dubinspath.w2(1)-dubinspath.ce(1)),2*pi);
  if dubinspath.lame>0,
      if th1>=th2,
        th = [th1:Del:2*pi,0:Del:th2];
      else
        th = [th1:Del:th2];
      end
  else
      if th1<=th2,
        th = [th1:-Del:0,2*pi:-Del:th2];
      else
        th = [th1:-Del:th2];
      end
  end
  for i=1:length(th),
    X = [X; dubinspath.ce(1)+dubinspath.R*cos(th(i))]; 
    Y = [Y; dubinspath.ce(2)+dubinspath.R*sin(th(i))];
  end
  
end
    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% downAtNE
%%   find the map down coordinate at a specified (n,e) location
function down = downAtNE(map, n, e)

      [d_n,idx_n] = min(abs(n - map.buildings_n));
      [d_e,idx_e] = min(abs(e - map.buildings_e));

      if (d_n<=map.BuildingWidth) & (d_e<=map.BuildingWidth),
          down = -map.heights(idx_e,idx_n);
      else
          down = 0;
      end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% findReturn
%%   compute the return value at a particular location
function return_value = findReturn(pn,pe,return_map,map);

  [pn_max,pe_max] = size(return_map);
  fn = pn_max*pn/map.width;
  fn = min(pn_max,round(fn));
  fn = max(1,fn);
  fe = pe_max*pe/map.width;
  fe = min(pe_max,round(fe));
  fe = max(1,fe);
  return_value = return_map(fn,fe);
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% findMaxReturnPath
%%   find the maximum return path in the tree
function path = findMaxReturnPath(tree)
    
     % find node with max return
    [tmp,idx] = max(tree(:,5));
    
    % construct path with maximum return
    path = tree(idx,:);
    parent_node = tree(idx,6);
    while parent_node>1,
        path = [tree(parent_node,:); path];
        parent_node = tree(parent_node,6);
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% updateReturnMap
%%   update the return map to indicate where MAV has been
function new_return_map = updateReturnMap(path,return_map,map)

  new_return_map = return_map;
  for i=1:size(path,1),
    pn = path(i,1);
    pe = path(i,2);
    [pn_max,pe_max] = size(return_map);
    fn = pn_max*pn/map.width;
    fn = min(pn_max,round(fn));
    fn = max(1,fn);
    fe = pe_max*pe/map.width;
    fe = min(pe_max,round(fe));
    fe = max(1,fe);
  
    new_return_map(fn,fe) = return_map(fn,fe) - 50;
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plotReturnMap
%%   plot the return map
function plotReturnMap(return_map);

  figure(2), clf 
  mesh(return_map)  
end

  
