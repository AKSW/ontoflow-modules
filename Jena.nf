params.debug = false

process mergeTtlFiles {
    debug params.debug
    container 'stain/jena:4.0.0'
    stageInMode 'copy'
    errorStrategy 'ignore'

    input: 
        path ttlFiles
    output:
        path 'merged-files.ttl', emit: mergedTtl

    """
    riot --quiet --formatted=Turtle $ttlFiles > "merged-files.ttl"
    """
}

process applySparqlOnRdf {
    container 'aksw/rpt:latest'
    debug params.debug
    input:
        path rdfInput
        path sparql
        val outName
    output:
        path "${outName}" // , emit: ttlOut
    
    """
    # defining rpt alias for compatibility with nextflows container invocation with entrypoint=/bin/bash ...
    # we need to activate alias expansion in script
    shopt -s expand_aliases
    alias rpt='java -cp @/app/jib-classpath-file org.aksw.rdf_processing_toolkit.cli.main.MainCliRdfProcessingToolkit'
    
    # debug output
    echo "rdfInput: ${rdfInput}"
    echo "sparql: ${sparql}"

    # run rpt
    # we need the construct query at the end to generate output that gets written to file
    rpt integrate ${rdfInput} --out-file='${outName}' ${sparql} 'construct {?s ?p ?o } where {?s ?p ?o}'
    """
}