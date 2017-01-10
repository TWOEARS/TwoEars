function clearTmp()
% delete content of 'src/tmp'

dir_path = db.tmp();

dirData = dir(dir_path);
dirIndex = [dirData.isdir];
for idx=find(dirIndex)
  if dirData(idx).name(1) ~= '.'
    rmdir(fullfile(dir_path, dirData(idx).name), 's')
  end
end
