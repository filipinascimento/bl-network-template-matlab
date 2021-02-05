function [] = main(configJsonFilename)
  % load our own config.json
  config = loadjson(configJsonFilename);
  
  % Getting input network
  networkPath = '';
  if isfield(config,'network')
      networkPath = config.network;
  end


  % Getting threshold parameter
  threshold = 0.0;
  if isfield(config,'threshold')
    threshold = config.threshold;
  end

  mkdir("output")

  graph = JGFGraph(networkPath)
  
  disp("Node Properties")
  disp(graph.nodeProperties)

  disp("Edge Matrices")
  disp(graph.weightNames)
  
  w = graph.weightMatrix;

  % Using threshold
  w(w<threshold) = 0;

  % Calculating node strength
  strengths = sum(w,1);

  % Plotting a histogram of node strengths
  f=figure;
  hist(strengths);
  saveas(f, 'output/report.pdf')
  
  
