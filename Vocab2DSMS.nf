process updateDataspace {
    errorStrategy 'ignore'
    container "python:3.12"
    containerOptions '--entrypoint="/bin/bash"'
    debug true
    input:
    	path ttl
        val dsmsUrl
        val dsmsUser
        val dsmsPass
        val identifier

    """
    pip install rdflib
    pip install dsms-sdk

    export DSMS_HOST_URL="$dsmsUrl"
    export DSMS_USERNAME="$dsmsUser"
    export DSMS_PASSWORD="$dsmsPass"
  
    python - <<EOF
    from dsms import DSMS
    from rdflib import Graph

    filePath = "$ttl"
    identifier = "$identifier"  # we can include versioning here
    repository = "vocabulary" # repo has to be 'vocabulary'

    dsms = DSMS()

    graph = Graph(identifier=identifier)
    graph.parse(filePath, format="turtle")
    graphSizeOrig = len(graph)
    print("graph size to be uploaded to DSMS:", graphSizeOrig)

    dsms.sparql_interface.subgraph.update(graph, repository=repository) # repo has to be 'vocabulary'

    graphDownload = dsms.sparql_interface.subgraph.get(identifier=identifier, repository=repository)
    print("graph size as downloaded from DSMS:", len(graphDownload))

    assert graphSizeOrig==len(graphDownload), "graph sizes should match"

    EOF
    """
}