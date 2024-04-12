params.debug = true

//TODO folders should be set within process and not only within script
process generateSites {
    container 'git.infai.org:4567/materialdigital/stahldigital/jod-for-stahl:latest'
    debug params.debug
    // beforeScript 'chmod a+w .'
    input:
        path ttl
    output:
        path '_site/htmls/*.html', emit: htmls
        path '_site/htmls', emit: htmls_dir, type: "dir"
        path '_site/*.html', emit: ontologyDescriptionHtml, type: "file"
        path "_site/ttls/*", emit: ttls
        path "_site/ttls", emit: ttls_dir, type: "dir"

        path '_site/ProcessOntology/*.html', emit: old_htmls
        path '_site/ProcessOntology', emit: old_htmls_dir, type: "dir"
        path '_site/ProcessOntology.html', emit: old_ontologyDescriptionHtml, type: "file"
        path "_site/ProcessOntology/ttl/*", emit: old_ttls
        path "_site/ProcessOntology/ttl", emit: old_ttls_dir, type: "dir"
    '''
    run_all.sh
    # Workaround for jod dir handling
    PROCESS_ONTOLOGY_DIR="_site/ProcessOntology"
    HTMLS_DIR="_site/htmls"
    OLD_TTLS_DIR="\${HTMLS_DIR}/ttl"
    TTLS_DIR="_site/ttls"
    if [ -d "\$PROCESS_ONTOLOGY_DIR" ]; then
        cp -r \$PROCESS_ONTOLOGY_DIR \$HTMLS_DIR
    fi

    if [ -d "\$OLD_TTLS_DIR" ]; then
        mv \$OLD_TTLS_DIR \$TTLS_DIR
    fi
    '''
}
