function baParamIdxs = baParams2bapIdxs( baParams )

emptyBapi = nanRescStruct;
baParamIdxs = repmat( emptyBapi, numel( baParams ), 1);

tmp = num2cell( nan2inf( [baParams.classIdx] ) );
[baParamIdxs.classIdx] = tmp{:};
tmp = num2cell( nan2inf( [baParams.dd] ) );
[baParamIdxs.dd] = tmp{:};
tmp = num2cell( nan2inf( [baParams.nAct] + 1 ) );
[baParamIdxs.nAct] = tmp{:};
tmp = num2cell( nan2inf( round( ([baParams.curSnr]+35)/5 ) + 1 ) );
[baParamIdxs.curSnr] = tmp{:};
tmp = num2cell( nan2inf( round( ([baParams.curSnr_db]+35)/5 ) + 1 ) );
[baParamIdxs.curSnr_db] = tmp{:};
tmp = num2cell( nan2inf( round( ([baParams.curSnr2]+35)/5 ) + 1 ) );
[baParamIdxs.curSnr2] = tmp{:};
tmp = num2cell( nan2inf( round( [baParams.azmErr]/5 ) + 1 ) );
[baParamIdxs.azmErr] = tmp{:};
tmp = num2cell( nan2inf( round( [baParams.azmErr2]/5 ) + 1 ) );
[baParamIdxs.azmErr2] = tmp{:};
tmp = num2cell( nan2inf( round( (wrapTo180([baParams.gtAzm])+180)/5 ) + 1 ) );
[baParamIdxs.gtAzm] = tmp{:};
tmp = num2cell( nan2inf( [baParams.nEstErr] + 4 ) );
[baParamIdxs.nEstErr] = tmp{:};
tmp = num2cell( nan2inf( [baParams.nAct_segStream] + 1 ) );
[baParamIdxs.nAct_segStream] = tmp{:};
tmp = num2cell( nan2inf( round( ([baParams.curNrj]+35)/5 ) + 1 ) );
[baParamIdxs.curNrj] = tmp{:};
tmp = num2cell( nan2inf( round( ([baParams.curNrj_db]+35)/5 ) + 1 ) );
[baParamIdxs.curNrj_db] = tmp{:};
tmp = num2cell( nan2inf( round( ([baParams.curNrjOthers]+35)/5 ) + 1 ) );
[baParamIdxs.curNrjOthers] = tmp{:};
tmp = num2cell( nan2inf( round( ([baParams.curNrjOthers_db]+35)/5 ) + 1 ) );
[baParamIdxs.curNrjOthers_db] = tmp{:};
tmp = num2cell( nan2inf( [baParams.scpId] ) );
[baParamIdxs.scpId] = tmp{:};
tmp = num2cell( nan2inf( [baParams.fileId] ) );
[baParamIdxs.fileId] = tmp{:};
tmp = num2cell( nan2inf( [baParams.fileClassId] ) );
[baParamIdxs.fileClassId] = tmp{:};
tmp = num2cell( nan2inf( [baParams.posPresent] + 1 ) );
[baParamIdxs.posPresent] = tmp{:};
tmp = num2cell( nan2inf( round( ([baParams.posSnr]+35)/5 ) + 1 ) );
[baParamIdxs.posSnr] = tmp{:};
tmp = num2cell( nan2inf( [baParams.blockClass] ) );
[baParamIdxs.blockClass] = tmp{:};
tmp = num2cell( nan2inf( ([baParams.dist2bisector]+1)*10 + 1 ) );
[baParamIdxs.dist2bisector] = tmp{:};

baParamIdxs = rmfield( baParamIdxs, 'estAzm' );

end

function v = nan2inf( v )
v(isnan( v ))= inf;
end