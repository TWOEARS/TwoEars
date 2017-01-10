classdef IdCacheTreeElem < handle
    
    properties (Access = {?Core.IdCacheDirectory})
        cfg;
        cfgSubs;
        path;
    end

    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = IdCacheTreeElem( cfg, path )
            if nargin < 1, cfg = []; end
            if nargin < 2, path = []; end
            obj.cfg = cfg;
            obj.cfgSubs = containers.Map('KeyType','char','ValueType','any');
            obj.path = path;
        end
        %% -------------------------------------------------------------------------------
        
        function treeNode = getCfg( obj, cfgList, createIfMissing )
            if nargin < 3, createIfMissing = false; end
            if isempty( cfgList ), treeNode = obj; return; end
            treeNode = obj;
            for ii = 1 : numel( cfgList )
                subTreeNode = [];
                cfgName = cfgList(ii).fieldname;
                cfgField = cfgList(ii).field;
                if treeNode.cfgSubs.isKey( cfgName )
                    subTreeNodes = treeNode.cfgSubs(cfgName);
                else
                    subTreeNodes = [];
                end
                for jj = 1 : numel( subTreeNodes )
                    subcfg = subTreeNodes(jj).cfg;
                    subcfgEqualsCfg = isequalDeepCompare( subcfg, cfgField );
                    if subcfgEqualsCfg
                        subTreeNode = subTreeNodes(jj);
                        break;
                    end
                end
                if isempty( subTreeNode )
                    if createIfMissing
                        newSubTrees = [Core.IdCacheTreeElem( cfgField ) subTreeNodes];
                        treeNode.cfgSubs(cfgName) = newSubTrees;
                        subTreeNode = newSubTrees(1);
                    else
                        return;
                    end
                end
                treeNode = subTreeNode;
            end
        end
        %% -------------------------------------------------------------------------------
        
        function deleteCfg( obj, cfgList )
            if isempty( cfgList ), return; end;
            treeNodeUnderInvestigation = obj;
            deleteTreeParts = true;
            for ii = 1 : numel( cfgList )
                subTreeNodeWithSameCfg = [];
                cfgName = cfgList(ii).fieldname;
                cfgField = cfgList(ii).field;
                if treeNodeUnderInvestigation.cfgSubs.isKey( cfgName )
                    subTreeNodesWithSameCfgName = treeNodeUnderInvestigation.cfgSubs(cfgName);
                else
                    deleteTreeParts = treeNodeUnderInvestigation.cfgSubs.Count == 0;
                    break; % arrived at a dead end -- cfgList does not exist in tree
                end
                for jj = 1 : numel( subTreeNodesWithSameCfgName )
                    subcfg = subTreeNodesWithSameCfgName(jj).cfg;
                    subcfgEqualsCfg = isequalDeepCompare( subcfg, cfgField );
                    if subcfgEqualsCfg
                        subTreeNodeWithSameCfg = subTreeNodesWithSameCfgName(jj);
                        break;
                    end
                end
                if isempty( subTreeNodeWithSameCfg )
                    deleteTreeParts = false;
                    break; % arrived at a dead end -- cfgList does not exist in tree
                    % delete nothing
                end
                if numel( subTreeNodesWithSameCfgName ) > 1  ||  ...
                        ~exist( 'lastMultiSubTreeNodes', 'var' )  ||  ...
                        ~isempty( treeNodeUnderInvestigation.path )  || ...
                        treeNodeUnderInvestigation.cfgSubs.Count > 1
                    lastMultiSubTreeNodesTreeNode = treeNodeUnderInvestigation;
                    lastMultiSubTreeNodesKey = cfgName;
                    lastMultiSubTreeNodesCfgIdx = jj;
                    lastMultiSubTreeNodes = subTreeNodesWithSameCfgName;
                end
                treeNodeUnderInvestigation = subTreeNodeWithSameCfg;
            end
            if deleteTreeParts
                if ~isempty( subTreeNodeWithSameCfg )
                    subTreeNodeWithSameCfg.path = [];
                    if subTreeNodeWithSameCfg.cfgSubs.Count == 0
                        lastMultiSubTreeNodes(lastMultiSubTreeNodesCfgIdx) = [];
                        if isempty( lastMultiSubTreeNodes )
                            lastMultiSubTreeNodesTreeNode.cfgSubs.remove( lastMultiSubTreeNodesKey );
                        else
                            lastMultiSubTreeNodesTreeNode.cfgSubs(lastMultiSubTreeNodesKey) = lastMultiSubTreeNodes;
                        end
                    end
                end
            end
        end
        %% -------------------------------------------------------------------------------
        
        function subTreeNode = getCfgSubtree( obj, cfgFieldName, cfg, createIfMissing )
            if nargin < 4, createIfMissing = false; end
            subTreeNode = [];
            subTreeNodes = obj.getCfgSubtrees( cfgFieldName );
            for ii = 1 : numel( subTreeNodes )
                subcfg = subTreeNodes(ii).cfg;
                subcfgEqualsCfg = isequalDeepCompare( subcfg, cfg );
                if subcfgEqualsCfg
                    subTreeNode = subTreeNodes(ii);
                    return;
                end
            end
            if createIfMissing
                newSubTrees = [Core.IdCacheTreeElem( cfg ) subTreeNodes];
                obj.cfgSubs(cfgFieldName) = newSubTrees;
                subTreeNode = newSubTrees(1);
            end
        end
        %% -------------------------------------------------------------------------------
        
        function subTreeNodes = getCfgSubtrees( obj, cfgFieldName )
            subTreeNodes = [];
            if obj.cfgSubs.isKey( cfgFieldName )
                subTreeNodes = obj.cfgSubs(cfgFieldName);
            end
        end
        %% -------------------------------------------------------------------------------
       
        function changesMade = integrateOtherTreeNode( obj, otherNode )
            changesMade = false;
            if ~isequalDeepCompare( obj.cfg, otherNode.cfg )
                error( 'this should not happen' );
            end
            if ~strcmp( obj.path, otherNode.path )
                if ~isempty( obj.path ) && ~isempty( otherNode.path )
                    copyfile( fullfile( obj.path, '*' ), ...
                              fullfile( otherNode.path, filesep ) );
                    rmdir( obj.path, 's' );
                    obj.path = otherNode.path;
                end
                if (isempty( obj.path ) || ~exist( obj.path, 'dir' )) ...
                        && ~isempty( otherNode.path )
                    obj.path = otherNode.path;
                end
                changesMade = true;
            end
            otherSubKeys = otherNode.cfgSubs.keys;
            for ii = 1 : numel( otherSubKeys )
                if obj.cfgSubs.isKey( otherSubKeys{ii} )
                    subCfgs = obj.cfgSubs(otherSubKeys{ii});
                    otherSubCfgs = otherNode.cfgSubs(otherSubKeys{ii});
                    for jj = 1 : numel( otherSubCfgs )
                        foundSubCfg = false;
                        for kk = 1 : numel( subCfgs )
                            if isequalDeepCompare( subCfgs(kk).cfg, otherSubCfgs(jj).cfg )
                                changesMade = integrateOtherTreeNode( ...
                                                          subCfgs(kk), otherSubCfgs(jj) );
                                foundSubCfg = true;
                                break;
                            end
                        end
                        if ~foundSubCfg
                            obj.cfgSubs(otherSubKeys{ii}) = [otherSubCfgs(jj) subCfgs];
                            changesMade = true;
                        end
                    end
                else
                    obj.cfgSubs(otherSubKeys{ii}) = otherNode.cfgSubs(otherSubKeys{ii});
                    changesMade = true;
                end
            end
        end
        %% -------------------------------------------------------------------------------
       
        function [leaves, cfgLists] = findAllLeaves( obj, cfgList )
            leaves = [];
            cfgLists = {};
            subKeys = obj.cfgSubs.keys;
            if isempty( subKeys )
                leaves = obj;
                cfgLists = {cfgList};
                return;
            end
            for ii = 1 : numel( subKeys )
                fn = subKeys{ii};
                subCfgs = obj.cfgSubs(subKeys{ii});
                for jj = 1 : numel( subCfgs )
                    f = subCfgs(jj).cfg;
                    fl = [cfgList struct('fieldname',{fn},'field',{f})];
                    [lvs, cl] = subCfgs(jj).findAllLeaves( fl );
                    leaves = [leaves; lvs];
                    cfgLists = [cfgLists; cl];
                end
            end
        end
        %% -------------------------------------------------------------------------------

    end
    
end
