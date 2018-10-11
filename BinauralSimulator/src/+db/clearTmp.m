function clearTmp()
% delete content of 'src/tmp'

dir_path = db.tmp();

for dirData = dir(dir_path).'
  if dirData.isdir
    if dirData.name(1) ~= '.'
        rmdir(fullfile(dir_path, dirData.name), 's')
    end
  else
      if dirData.name(1) ~= '.' || strcmp(dirData.name, '.dir.flist')
         delete(fullfile(dir_path, dirData.name));
      end
  end
end
