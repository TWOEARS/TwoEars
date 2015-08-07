function bbs = buildIdentificationBBS(sim,idModels,labels,onOffsets)

bbs = BlackboardSystem(1);
bbs.setRobotConnect(sim);
bbs.setDataConnect('AuditoryFrontEndKS');
for ii = 1 : numel( idModels )
    idKss{ii} = bbs.createKS('IdentityKS', {idModels(ii).name, idModels(ii).dir});
    idKss{ii}.setInvocationFrequency(10);
end
idCheat = bbs.createKS('IdTruthPlotKS', {labels, onOffsets});
bbs.blackboardMonitor.bind({bbs.scheduler}, {bbs.dataConnect}, 'replaceOld', 'AgendaEmpty' );
bbs.blackboardMonitor.bind({bbs.dataConnect}, idKss, 'replaceOld' );
bbs.blackboardMonitor.bind(idKss, {idCheat}, 'replaceParallelOld' );
