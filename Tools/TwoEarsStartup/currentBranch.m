function branchName = currentBranch( repoDir )

dirTmp = pwd;
cd( repoDir );

branchReturn = git( 'branch' );
branchSignPos = strfind( branchReturn, '*' );
if isempty(branchSignPos)
    error( ['Was not able to determine the current branch. ' ...
        'Maybe your git binary dir is not included in the system path?'] );
end
branchName = sscanf( branchReturn(branchSignPos+1:end), '%s', 1 );

cd( dirTmp );