classdef JGFGraph
   properties
    graph
   end
   methods
    function obj = JGFGraph(networkPath)
      % jgfload  loads the graphJSON file in networkpath.
      %   use as
      %   graph = jgfload(networkpath)
      %

      tempJSON = tempname;
      exportedFiles = gunzip(networkPath,tempJSON);
      networkData = loadjson(string(exportedFiles),'UseMap',1);
      
      graphJSON = networkData("graph");
      graph = containers.Map;
      hasNodes = isKey(graphJSON,"nodes");
      hasEdges = isKey(graphJSON,"edges");
  
      if(~hasNodes && hasEdges)
        disp("JGF files must contain 'nodes' if 'edges' is defined.");
        return;
      end
  
      directed = false;
  
      if(isKey(graphJSON,"directed"))
        directed = graphJSON("directed");
      else
        disp("'directed' was not found in the JGF file. This parser only works for fully directed/undirected networks. The whole network is now considered undirected.");
      end
  
      graphProperties = containers.Map;
      
      if(isKey(graphJSON,"label"))
        graph("label") = graphJSON("label");
      end
      
      if(isKey(graphJSON,"id"))
        graphProperties("id") = graphJSON("id");
      end
  
      if(isKey(graphJSON,"type"))
        graphProperties("type") = graphJSON("type");
      end
  
  
  
      graph("directed") = directed;
  
      if(hasNodes)
        graph("node-count") = length(graphJSON("nodes"));
      end
      
      if(isKey(graphJSON,"metadata"))
        graphMetadata = graphJSON("metadata");
        for k = keys(graphMetadata)
          key = k{1};
          value = graphMetadata(key);
          graphProperties(key) = value;
        end
      end
  
      if(length(graphProperties)>0)
        graph("network-properties") = graphProperties;
      end
  
  
      nodeProperties = containers.Map;
      nodeIDToIndex = containers.Map;
      nodeIndexToID = {};
      digitIndices = true;
      if(hasNodes)
        nodes = graphJSON("nodes");
        for nodeIDk = keys(nodes)
          nodeID = nodeIDk{1};
          nodeData = nodes(nodeID);
          if(~isKey(nodeIDToIndex,nodeID))
            nodeIDToIndex(nodeID) = length(nodeIndexToID);
            nodeIndexToID{end+1} = nodeID;
          end
          for k = keys(nodeData)
            key = k{1};
            value = nodeData(key);
            if(key~="metadata")
              if(~isKey(nodeProperties,key))
                nodeProperties(key) = containers.Map;
              end
              nodePropertiesMap = nodeProperties(key);
              nodePropertiesMap(nodeID) = value;
            end
          end
          if(isKey(nodeData,"metadata"))
            nodeMetadata = nodeData("metadata");
            for k = keys(nodeMetadata)
              key = k{1};
              value = nodeMetadata(key);
              if(~isKey(nodeProperties,key))
                nodeProperties(key) = containers.Map;
              end
              nodePropertiesMap = nodeProperties(key);
              nodePropertiesMap(nodeID) = value;
            end
          end
        end
        
        for k = keys(nodeProperties)
          key = k{1};
          value = nodeProperties(key);
          %all nodes have property so convert it to an array
          propertyArray = {};
          nodePropertyForKey = nodeProperties(key);
          areAllNumeric = true;
          for IDk = keys(nodeIDToIndex)
            ID = IDk{1};
            index = nodeIDToIndex(ID)+1;
            if(isKey(nodePropertyForKey,ID))
              pvalue = nodePropertyForKey(ID);
              propertyArray{index} = pvalue;
              if(~isnumeric(pvalue))
                areAllNumeric = false;
              end
            else
              propertyArray{index} = NaN;
            end
          end
          if(areAllNumeric)
            propertyArray = cell2mat(propertyArray);
          end
          nodeProperties(key) = propertyArray;
        end
      end
      
      edgeMatrices = containers.Map;
      if(hasEdges)
        nodeCount = length(nodes);
        edgesData = graphJSON("edges");
        isWeighted = false;
        % Check if network is layered or/and weighted
        edgePropertiesIsNumeric = containers.Map;
        for e = edgesData
          edge = e{1};
          if(isKey(edge,"metadata"))
            metadata = edge("metadata");
            for k = keys(metadata)
              key = k{1};
              value = metadata(key);
              if(key=="weight")
                isWeighted = true;
              else
                if(isnumeric(value) & ~isKey(edgePropertiesIsNumeric,key))
                  edgePropertiesIsNumeric(key) = true;
                elseif(~isnumeric(value))
                  edgePropertiesIsNumeric(key) = false;
                end
              end
            end
          end
        end
        %Initializing matrices
        for k = keys(edgePropertiesIsNumeric)
          key = k{1};
          if(edgePropertiesIsNumeric(key))
            edgeMatrices(key) = zeros(nodeCount);
          else
            edgeMatrices(key) = cell(nodeCount,nodeCount);
          end
        end
        
        edgeMatrices("weight") = zeros(nodeCount);
        
        for e = edgesData
          edge = e{1};
          sourceIndex = nodeIDToIndex(edge("source"))+1;
          targetIndex = nodeIDToIndex(edge("target"))+1;
          if(~isWeighted)
            m = edgeMatrices("weight");
            m(sourceIndex,targetIndex) = 1;
            if(~directed)
              m(targetIndex,sourceIndex) = 1;
            end
            edgeMatrices("weight") = m;
          end
          if(isKey(edge,"metadata"))
            metadata = edge("metadata");
            for k = keys(metadata)
              key = k{1};
              value = metadata(key);
              
              m = edgeMatrices(key);
              
              if(key=="weight" | edgePropertiesIsNumeric(key))
                m(sourceIndex,targetIndex) = value;
                if(~directed)
                  m(targetIndex,sourceIndex) = value;
                end
              else
                m{sourceIndex,targetIndex} = value;
                if(~directed)
                  m{targetIndex,sourceIndex} = value;
                end
              end
              edgeMatrices(key) = m;
            end
            if(isKey(metadata,"layer"))
              if(metadata("layer")=="negative")
                m = edgeMatrices("weight");
                m(sourceIndex,targetIndex) = -m(sourceIndex,targetIndex);
                if(~directed)
                  m(targetIndex,sourceIndex) = -m(targetIndex,sourceIndex);
                end
                edgeMatrices("weight") = m;
              end
            end
          end
        end
      end

      if(length(edgeMatrices)>0)
        graph("edges") = edgeMatrices;
      end
      if(length(nodeProperties)>0)
        graph("node-properties") = nodeProperties;
      end
      graph("directed") = directed;
      obj.graph = graph;
    end
    function matrix = weightMatrix(obj,name)
      key = "weight";
      if nargin == 2
        key=name;
      end
      edgeMatrices = obj.graph("edges");
      matrix = edgeMatrices(key);
    end
    function names = weightNames(obj)
      edgeMatrices = obj.graph("edges");
      names = {};
      for k = keys(edgeMatrices)
        key=k{1};
        names{end+1} = key;
      end
    end

    function properties = nodeProperty(obj,name)
      if(isKey(obj.graph,"node-properties"))
        nodeProperties = obj.graph("node-properties");
        if(isKey(nodeProperties,name))
          properties = nodeProperties(name)
        else
          error(strcat("Property '",name,"' not found in graph."))
          return
        end
      else
        error(strcat("Property '",name,"' not found in graph."))
        return
      end
    end
    function names = nodeProperties(obj)
      names = {};
      if(isKey(obj.graph,"node-properties"))
        nodeProperties = obj.graph("node-properties");
        for k = keys(nodeProperties)
          key=k{1};
          names{end+1} = key;
        end
      end
    end
   end
end

