function bbs = buildIdentificationBBS(sim,idModels,ppRemoveDc,fs,labels,onOffsets,segmBb)

bbs = BlackboardSystem(1);
bbs.setRobotConnect(sim);
bbs.setDataConnect('AuditoryFrontEndKS',fs);
if segmBb
    addPathsIfNotIncluded( {...
        cleanPathFromRelativeRefs( [pwd '/../../../../segmentation-training-pipeline/src'] ), ...
        cleanPathFromRelativeRefs( [pwd '/../../../../segmentation-training-pipeline/external/data-hash'] ), ...
        cleanPathFromRelativeRefs( [pwd '/../../../../segmentation-training-pipeline/external/yaml-matlab'] ) ...
        } );
    segmModelFileName = '3d5c7e6a0ec5ce057e927caab172df32.mat';
    mkdir( fullfile( db.tmp, 'learned_models', 'SegmentationKS' ) );
    copyfile(  cleanPathFromRelativeRefs( [pwd '/../../../../AMLTTP/test/' segmModelFileName] ), ...
               fullfile( db.tmp, 'learned_models', 'SegmentationKS', segmModelFileName ), ...
               'f' );
    dnnloc = bbs.createKS( 'DnnLocationKS' );
    fprintf( '.' );
    nsrcs = bbs.createKS( 'NumberOfSourcesKS', {'nSrcs','learned_models/NumberOfSourcesKS/mc3_models_dataset_1',ppRemoveDc} );
    fprintf( '.' );
    segment = bbs.createKS( 'StreamSegregationKS', {cleanPathFromRelativeRefs( [pwd '/../../../../AMLTTP/test/SegmentationTrainerParameters2.yaml'] )} );
    fprintf( '.' );
    for ii = 1 : numel( idModels )
        idKss{ii} = bbs.createKS('SegmentIdentityKS', {idModels(ii).name, idModels(ii).dir, ppRemoveDc});
        fprintf( '.' );
        idKss{ii}.setInvocationFrequency(10);
    end
else
    for ii = 1 : numel( idModels )
        idKss{ii} = bbs.createKS('IdentityKS', {idModels(ii).name, idModels(ii).dir, ppRemoveDc});
        idKss{ii}.setInvocationFrequency(10);
    end
end
%idCheat = bbs.createKS('IdTruthPlotKS', {labels, onOffsets});
%idCheat.setYLimTimeSignal([-3, 3]*1e-2);
bbs.blackboardMonitor.bind({bbs.scheduler}, {bbs.dataConnect}, 'replaceOld', 'AgendaEmpty' );
if segmBb
    bbs.blackboardMonitor.bind({bbs.dataConnect}, {dnnloc}, 'replaceOld' );
    bbs.blackboardMonitor.bind({dnnloc}, {nsrcs}, 'replaceOld' );
    bbs.blackboardMonitor.bind({nsrcs}, {segment}, 'replaceOld' );
    bbs.blackboardMonitor.bind({segment}, idKss, 'replaceOld' );
else
    bbs.blackboardMonitor.bind({bbs.dataConnect}, idKss, 'replaceOld' );
end
%bbs.blackboardMonitor.bind(idKss, {idCheat}, 'replaceParallelOld' );
