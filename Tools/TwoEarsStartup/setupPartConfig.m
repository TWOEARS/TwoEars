function setupPartConfig( configFileName )

[reposNeeded, subsNeeded, recursiveSubsNeeded, branchesNeeded, startupNeeded] = getPartRequirements( configFileName );

for k = 1:length(reposNeeded)
    % Get path of TwoEars part (repository)
    repoPath = readPathConfig( 'TwoEarsPaths.xml', reposNeeded{k} );
    % Check if the correct branch is checked out. Note, this is only executed if
    % you specify a branch in the config file.
    if length(branchesNeeded{k})>0
        repoBranch = currentBranch( repoPath );
        if ~strcmp( repoBranch, branchesNeeded{k} )
            error( '"%s" needs to be checked out at "%s" branch, but current branch is "%s".', ...
                repoPath, branchesNeeded{k}, repoBranch );
        end
    end
    % Adding single subs (without subfolders)
    addpath( fullfile( repoPath, subsNeeded{k} ) );
    % Adding subs with all subfolders
    if recursiveSubsNeeded{k}
        addpath( genpath( fullfile( repoPath, recursiveSubsNeeded{k} ) ) );
    end
    % Execute startup function
    if ~isempty( startupNeeded{k} )
        startupFunc = str2func( startupNeeded{k} );
        startupFunc();
    end
end
