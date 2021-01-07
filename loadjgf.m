function graph = loadjgf(graphJSON)
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
      for IDk = keys(nodeIDToIndex)
        ID = IDk{1};
        index = nodeIDToIndex(ID)+1;
        if(isKey(nodePropertyForKey,ID))
          propertyArray{index} = nodePropertyForKey(ID);
        end
          propertyArray{index} = NaN;
      end
    end
  end


  
%   edges = []
%   edgeProperties = OrderedDict()
%   if(hasEdges):
%     for edgeIndex, edgeData in enumerate(graphJSON["edges"]):
%       hasSource = "source" in edgeData
%       hasTarget = "target" in edgeData
%       if(not hasSource or not hasTarget):
%         raise JGFParseError("Edges must contain both source and target attributes.")
      
%       sourceID = edgeData["source"]
%       targetID = edgeData["target"]

%       if(sourceID not in nodeIDToIndex or targetID not in nodeIDToIndex):
%         raise JGFParseError("Node %s is not present in the list of nodes. The file was not loaded."%sourceID)
      
%       sourceIndex = nodeIDToIndex[sourceID]
%       targetIndex = nodeIDToIndex[targetID]
%       edges.append((sourceIndex,targetIndex))

%       for key,value in edgeData.items():
%         if(key!="metadata" and key!="source" and key!="target"):
%           if(key not in edgeProperties):
%             edgeProperties[key] = OrderedDict()
%           edgeProperties[key][edgeIndex] = value
      
%       if("metadata" in edgeData):
%         for key,value in edgeData["metadata"].items():
%           if(key not in edgeProperties):
%             edgeProperties[key] = OrderedDict()
%           edgeProperties[key][edgeIndex] = value
    
%     for key in edgeProperties:
%       if(len(edgeProperties[key]) == len(edges)):
%         #all nodes have property so convert it to an array
%         edgeProperties[key] = [edgeProperties[key][ID] for ID in edgeProperties[key]]
%       else:
%         #some nodes do not have this property, so reindex it
%         edgeProperties[key] = OrderedDict((ID,value) for ID,value in edgeProperties[key].items())

%   if(len(edges)>0):
%     graph["edges"] = edges
  if(length(nodeProperties)>0)
    graph("node-properties") = nodeProperties;
%   if(len(edgeProperties)>0):
%     graph["edge-properties"] = edgeProperties
%   return graph
end