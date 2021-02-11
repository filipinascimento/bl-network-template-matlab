function [] = main(configJsonFilename)
  % load our own config.json
  config = loadjson(configJsonFilename);
  
  % Getting input network
  networkPath = '';
  if isfield(config,'network')
      networkPath = config.network;
  end

  % Getting threshold parameter
  threshold = 0.5;
  if isfield(config,'threshold')
    threshold = config.threshold;
  end

  mkdir("output")

  graph = JGFGraph(networkPath)
  
  disp("Node Properties")
  disp(graph.nodeProperties)

  disp("Edge Matrices")
  disp(graph.weightNames)
  
  % loading the main weight matrix
  w = graph.weightMatrix;

  % Using threshold
  w(w<=threshold) = 0;
  w(w>threshold) = 1;

  % Calculating node degree
  degrees = sum(w,1);

  % Plotting a histogram of node degrees
  f=figure;
  hist(degrees);
  saveas(f, 'output/report.pdf')
  
  
