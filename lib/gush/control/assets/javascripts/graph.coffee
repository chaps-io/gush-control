class @Graph
  constructor: (canvas_id) ->
    @canvas = "##{canvas_id}"
    @digraph = new dagreD3.Digraph

  populate: (nodes, links) ->
    nodes.forEach (node) =>
      @digraph.addNode node.name,
        finished: node.finished,
        failed: node.failed,
        running: node.running,
        label: node.name

    links.forEach (edge) =>
      @digraph.addEdge(null, edge.source, edge.target)

  render: ->
    renderer = new dagreD3.Renderer
    layout = dagreD3.layout().nodeSep(20).rankDir("LR");
    oldDrawNodes = renderer.drawNodes()

    renderer.drawNodes (graph, root) =>
      svgNodes = oldDrawNodes(graph, root);
      svgNodes.attr "class", (name) =>
        node = @digraph.node(name)
        classes = "node " + name.replace(/::/g, '_').toLowerCase()
        if node.finished
          classes += " status-finished";
        if node.failed
          classes += " status-failed";
        if node.running
          classes += " status-running";
        classes;

      svgNodes;
    .layout(layout)
    .run(@digraph, d3.select("#{@canvas} g"));
    @panZoom()

  panZoom: ->
    svgPanZoom @canvas,
      panEnabled: true,
      minZoom: 0.8,
      maxZoom: 10,
      zoomEnabled: true,
      center: false,
      fit: true
