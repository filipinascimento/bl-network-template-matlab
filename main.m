function [] = main(configJsonFilename)

  % load our own config.json
  config = loadjson(configJsonFilename);
  
  networkPath = '';
  if isfield(config,'network')
      networkPath = config.network;
  end
  
  tempJSON = tempname;
  exportedFiles = gunzip(networkPath,tempJSON);
  networkData = loadjson(string(exportedFiles),'UseMap',1);
  disp(networkData);
  
  graph = networkData("graph");
  nodes = graph("nodes");
  edges = graph("edges");
  disp(loadjgf(graph));
  % for k = keys(nodes)
  %   int(k{1})
  % end