params.debug = false

include { mergeTtlFiles as mergeShaclShapes } from './Jena'
include { renameFile } from './Util'


process shortenValidationResultTxt {
    input:
        file validationResultTxtIn
    output:
        path 'validation-report.txt', emit: validationResultTxt
        path 'validation-report-long.txt', emit: validationResultLongTxt
        
    """
    mv "$validationResultTxtIn" 'validation-report-long.txt'
    grep -e "Message:" -e "^Conforms: " -e "^Validation Report" -e "^Results " 'validation-report-long.txt' > 'validation-report.txt'
    echo "maybe some result lines are missing if they do not print out a message line." >> 'validation-report.txt'
    """
}

// all shapes need to be in a single file
process validate {
    debug params.debug
    //container 'docker.io/ashleysommer/pyshacl:latest' //seems to have problems with nextflow: "Error: executable file `/bin/bash` not found in $PATH"
    container 'registry.gitlab.com/infai/ontoflow/pyshacl:main'
    input:
        file rdfGraph
        file shaclShapes
    output:
        path 'validation-report.ttl', emit: validationResultTtl
        path 'validation-report.txt', emit: validationResultTxt
        path 'validation-report.table.txt', emit: validationResultTable

    // pyshacl indicates the result with exit codes, so we want to continue for non zero exit codes as well
    """
    pyshacl --allow-warnings --shacl "$shaclShapes" --format turtle --output "validation-report.ttl" "$rdfGraph" || errCode=\$?
    pyshacl --allow-warnings --shacl "$shaclShapes" --format human --output "validation-report.txt" "$rdfGraph" || errCode=\$?
    pyshacl --allow-warnings --shacl "$shaclShapes" --format table --output "validation-report.table.txt" "$rdfGraph" || errCode=\$?
    case "\$errCode" in
        0) echo "RDF graph is Conformant" ;;
        1) echo "RDF graph is not Conformant";;
        *) echo "other pySHACL error: \$?"; exit "\$?" ;;
    esac
    """
}

// validate with shapes distributed over many files
workflow validateWithShapeFilesWorkflow {
    take: 
        shapeFiles
        rdfGraph
    main:
        mergeShaclShapes( shapeFiles.collect() )
        view(mergeShaclShapes.out.mergedTtl)
        renameFile(mergeShaclShapes.out.mergedTtl, "shaclShapes.ttl")
        validate(
                rdfGraph,
                renameFile.out
        )
    emit:
        validationResultTxt = validate.out.validationResultTxt
        validationResultTable = validate.out.validationResultTable
        validationResultTtl = validate.out.validationResultTtl
        shaclShapesTtl = renameFile.out
}