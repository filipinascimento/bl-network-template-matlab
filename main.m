function [] = main(configJsonFilename)
  % load our own config.json
  config = loadjson(configJsonFilename);
  
  networkPath = '';
  if isfield(config,'network')
      networkPath = config.network;
  end
  mkdir("output")

  graph = JGFGraph(networkPath)
  
  disp("Node Properties")
  disp(graph.nodeProperties)

  disp("Edge Matrices")
  disp(graph.weightNames)
  
  w = graph.weightMatrix;

  % Calculating node strength
  strengths = sum(w,1);

  % Plotting a histogram of node strengths
  f=figure;
  hist(strengths);
  saveas(f, 'output/report.pdf')
  
  
