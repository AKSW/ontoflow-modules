process serializeRDFFiles {
    container "pheyvaer/raptor"
    containerOptions '--entrypoint="/bin/bash"'
    stageInMode 'copy'
    debug true
    input:
        path ttl_site
    output:
        path "serializations/*", emit: serializations, type: "file"
        path "serializations", emit: serializations_dir, type:"dir"

        """
        for file in *.ttl
        do
            rapper -i turtle -o ntriples "\${file}" | sort -u --parallel=16 > "\$(basename -s .ttl \${file})".nt
            rapper -i turtle -o rdfxml "\${file}" > "\$(basename -s .ttl \${file})".rdf
            rapper -i turtle -o json "\${file}" > "\$(basename -s .ttl \${file})".json
        done
        mkdir .serializations
        mv ./* .serializations/
        mv .serializations/ serializations
        """
}
