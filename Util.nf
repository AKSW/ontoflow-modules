params.artifactFolder = "$launchDir/Artifacts"
params.debug = true

def collectOutputChannels(process) {
    Channel.empty().mix(process.out).collect()
}

process renameFile {
    input:
        path input
        val newName
    output:
        path "*"

    """
    mv "$input" "$newName"
    """
}

/**
* Collect all files and or folders from the input into the
* a specified output directory.
* 
* This process uses the publishDir directive
* https://www.nextflow.io/docs/edge/process.html#publishdir
* and overwrites all files with the same name inside the $outDir.
*
* Without a full path the folder is created inside $launchDir.
* 
* Alternatives for publishDir directive
* 
* There are three alternatives to publishDir
* 1. Script with cp -r
* 2. storeDir directive
* 3. scratch directive
* 
* All alternative increase the potential for errors. `cp -r`
* requeries a fullpath otherwise files are stored inside the job
* folder. `storeDir` won't overwrite files already inside the $storeDir
* but pass the existing files into the output channel. `cache` does
* not store the files within the job folder.
* Since Nextflow is still evolving these statements have to be 
* reevaluated
* https://www.nextflow.io/docs/edge/process.html#scratch
* https://www.nextflow.io/docs/edge/process.html#storedir 
*
* Example usage
*
* <pre>
* {@code f = channel.fromPath("$projectDir/main.nf") }
* {@code collectFiles(f, "artifacts") }
* {@code collectFiles.out.view() }
* </pre>
* 
* @param files_folders a channel with paths to files and or folders
* @param outDir name of path to the output folder
* 
* @return files_folders are passed to the output so this process 
*                       can be used in a chain
*
* @author Kirill Bulert, bulert@infai.org, @kibubu
* 
*/
process collectFilesToFolder{
    debug params.debug

    publishDir path: "$outDir", mode: "copy", overwrite: true
    
    // storeDir directive approach 
    // storeDir "$outDir"
    // stageOutMode "copy"

    // scratch directive approach
    // scratch "$outDir"

    input:
        path files_folders
        val outDir
    output:
        path files_folders

    // A valid process requieres at least
    // an empty string, or `exec:` key
    // https://www.nextflow.io/docs/edge/process.html#script
    """
      # Script approach
      # mkdir -p "$outDir"
      # for f in "$files_folders";
      #   cp -r "\$f" "$outDir"
      # done
    """
}

/**
* Wrapper for collectFilesToFolder
* 
* @param files_folders a channel with paths to files and or folders
*
* @return files_folders are passed to the output so this process 
*                       can be used in a chain
*
* @author Kirill Bulert, bulert@infai.org, @kibubu
*/
workflow collectArtifacts{
take:
    files_folders
main:
    collectFilesToFolder(
        files_folders,
        params.artifactFolder)
emit:
    collectFilesToFolder.out
}

process countTriplesInIndexNT {
    debug params.debug
    input:
        path input
    output:
        stdout emit: out
        path "stats.txt", emit: statsTxt

    shell:
    '''
    echo "triples generated:" "$(sort -u '!{input}/index.nt' | wc --lines)" | tee -a stats.txt
    '''
}

process miniRdfStatsInIndexNT {
    container 'aksw/rpt:latest'
    debug params.debug
    input:
        file rdfInput
    output:
        stdout emit: out
        path "stats.csv", emit: statsCsv
    
    """
    # defining rpt alias for compatibility with nextflows container invocation with entrypoint=/bin/bash ...
    # we need to activate alias expansion in script
    shopt -s expand_aliases
    alias rpt='java -cp @/app/jib-classpath-file org.aksw.rdf_processing_toolkit.cli.main.MainCliRdfProcessingToolkit'
    
    rpt integrate --out-format=csv '${rdfInput}' --out-file='stats.csv' 'SELECT * WHERE { { SELECT (count(*) as ?triplesCount) WHERE { ?a ?b ?c . } } { SELECT (COUNT(DISTINCT ?class) as ?classesCount) WHERE { ?class a ?classDef . FILTER ( ?classDef IN (owl:Class, rdfs:Class) ) } } { SELECT (COUNT(DISTINCT ?property) as ?propertiesCount) WHERE { ?property a ?propertyDef . FILTER ( ?propertyDef IN (rdf:Property, owl:ObjectProperty, owl:DatatypeProperty) ) } } }'
    cat stats.csv
    """
}