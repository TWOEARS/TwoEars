classdef ReadersWritersFileSemaphore < handle
    
    %% -----------------------------------------------------------------------------------
    properties (SetAccess = protected)
        rmutex = [];
        wmutex = [];
        readTry = [];
        resource = [];
        xchange = [];
        rmutexSname = [];
        wmutexSname = [];
        readTrySname = [];
        fileToBeProtected = [];
        xchangeSname = [];
        rCountsFile = [];
        wCountsFile = [];
        xchangeFile = [];
    end
    
    %% -----------------------------------------------------------------------------------
    methods
        
        function obj = ReadersWritersFileSemaphore( filename )
            obj.fileToBeProtected = filename;
            obj.readTrySname = [obj.fileToBeProtected '.readTry'];
            obj.rmutexSname = [obj.fileToBeProtected '.rmutex'];
            obj.wmutexSname = [obj.fileToBeProtected '.wmutex'];
            obj.xchangeSname = [obj.fileToBeProtected '.xchange'];
            obj.rCountsFile = [obj.fileToBeProtected '.rCounts.mat'];
            obj.wCountsFile = [obj.fileToBeProtected '.wCounts.mat'];
            obj.xchangeFile = [obj.fileToBeProtected '.xchange.mat'];
            obj.rmutex = setfilesemaphore( obj.rmutexSname ); 
            obj.wmutex = setfilesemaphore( obj.wmutexSname ); 
            obj.xchange = setfilesemaphore( obj.xchangeSname ); 
            if ~exist( obj.rCountsFile, 'file' )
                readcount = 0;
                writecount = 0;
                rwSemasCount = 1;
                resourceSema = [];
                rtrySema = [];
                save( obj.rCountsFile, 'readcount' );
                save( obj.wCountsFile, 'writecount' );
                save( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
            else
                load( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
                rwSemasCount = rwSemasCount + 1;
                save( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
            end
            removefilesemaphore( obj.xchange ); 
            removefilesemaphore( obj.rmutex ); 
            removefilesemaphore( obj.wmutex ); 
        end
        %% -------------------------------------------------------------------------------
        
        function delete( obj )
            obj.xchange = setfilesemaphore( obj.xchangeSname ); 
            load( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
            rwSemasCount = rwSemasCount - 1;
            if rwSemasCount > 0
                save( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
            else
                delete( obj.rCountsFile );
                delete( obj.wCountsFile );
                delete( obj.xchangeFile );
            end
            removefilesemaphore( obj.xchange ); 
        end
        %% -------------------------------------------------------------------------------
        
        function getReadAccess( obj )
            obj.readTry = setfilesemaphore( obj.readTrySname ); %Indicate a reader is trying to enter
            obj.rmutex = setfilesemaphore( obj.rmutexSname ); %lock entry section to avoid race condition with other readers
            load( obj.rCountsFile, 'readcount' );
            readcount = readcount + 1; %report yourself as a reader
            if readcount == 1 %checks if you are first reader
                obj.resource = setfilesemaphore( obj.fileToBeProtected ); %if you are first reader, lock the resource
                obj.xchange = setfilesemaphore( obj.xchangeSname );
                load( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
                resourceSema = obj.resource;
                save( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
                removefilesemaphore( obj.xchange );
            end
            save( obj.rCountsFile, 'readcount' );
            removefilesemaphore( obj.rmutex ); %release entry section for other readers
            removefilesemaphore( obj.readTry ); %indicate you are done trying to access the resource
        end
        %% -------------------------------------------------------------------------------
        
        function releaseReadAccess( obj )
            obj.rmutex = setfilesemaphore( obj.rmutexSname ); %reserve exit section - avoids race condition with readers
            load( obj.rCountsFile, 'readcount' );
            readcount = readcount - 1;%indicate you're leaving
            save( obj.rCountsFile, 'readcount' );
            if readcount == 0 %checks if you are last reader leaving
                obj.xchange = setfilesemaphore( obj.xchangeSname );
                load( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
                obj.resource = resourceSema;
                removefilesemaphore( obj.resource ); %if last, you must release the locked resource
                removefilesemaphore( obj.xchange );
            end
            removefilesemaphore( obj.rmutex ); %release exit section for other readers
        end
        %% -------------------------------------------------------------------------------
        
        function getWriteAccess( obj )
            obj.wmutex = setfilesemaphore( obj.wmutexSname ); %reserve entry section for writers - avoids race conditions
            load( obj.wCountsFile, 'writecount' );
            writecount = writecount + 1; %report yourself as a writer entering
            save( obj.wCountsFile, 'writecount' );
            if writecount == 1 %checks if you're first writer
                obj.readTry = setfilesemaphore( obj.readTrySname ); %if you're first, then you must lock the readers out. Prevent them from trying to enter CS
                obj.xchange = setfilesemaphore( obj.xchangeSname );
                load( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
                rtrySema = obj.readTry;
                save( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
                removefilesemaphore( obj.xchange );
            end
            removefilesemaphore( obj.wmutex ); %release entry section
            obj.resource = setfilesemaphore( obj.fileToBeProtected ); %reserve the resource for yourself - prevents other writers from simultaneously editing the shared resource
        end
        %% -------------------------------------------------------------------------------
        
        function releaseWriteAccess( obj )
            removefilesemaphore( obj.resource ); %release file
            obj.wmutex = setfilesemaphore( obj.wmutexSname ); %reserve exit section
            load( obj.wCountsFile, 'writecount' );
            writecount = writecount - 1; %indicate you're leaving
            save( obj.wCountsFile, 'writecount' );
            if writecount == 0 %checks if you're the last writer
                obj.xchange = setfilesemaphore( obj.xchangeSname );
                load( obj.xchangeFile, 'rwSemasCount', 'resourceSema', 'rtrySema' );
                obj.readTry = rtrySema;
                removefilesemaphore( obj.readTry ); %if you're last writer, you must unlock the readers. Allows them to try enter CS for reading
                removefilesemaphore( obj.xchange );
            end
            removefilesemaphore( obj.wmutex ); %release exit section
        end
    end
    %% -------------------------------------------------------------------------------
    
end
