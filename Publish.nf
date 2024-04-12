process pushToQuitstoreRepository {
    container 'ubuntu:22.04'
    //beforeScript "apt update && apt install -y git raptor2-utils"
    // echo true
    input:
        path ttl
    val repo from params.storeRepository
    env QUITSTORE_TOKEN
    env QUITSTORE_USER
    val userEmail from params.userEmail
    val userName from params.userName

    """
    apt update
    apt install -y git raptor2-utils
    git config --global credential.helper '!f() { echo "username=${QUITSTORE_USER}"; echo "password=${QUITSTORE_TOKEN}"; }; f'
    git clone "https://git.infai.org/materialdigital/stahldigital/store.git"

    cd store
    # rapper -i turtle -o ntriples $ttl | LC_ALL=C sort -u > SteelProcessOntology.nt
    rapper -i turtle -o ntriples ../$ttl | LC_ALL=C sort -u > SteelProcessOntology.nt && git add SteelProcessOntology.nt

    if [ -n "\$(git status -s)" ]; then
        git config --global user.email "$userEmail"
        git config --global user.name "$userName"
        git commit -m "Pushing latest changes"
        git push
    fi
    """
}

process _publish{
    debug true
    container 'bitnami/git'
    stageInMode 'copy'

    input:
    path more_rdf
    path site
    val publishRepository
    path deployKey
    val userEmail
    val userName
    path known_hosts
    script:
    publishRepositoryFolder = 'publishRepository'

    """
    eval \$(ssh-agent)
    chmod 600 $deployKey
    ssh-add $deployKey
    mkdir ~/.ssh
    cp $known_hosts ~/.ssh/known_hosts
    git clone $publishRepository $publishRepositoryFolder
    mkdir -p $publishRepositoryFolder/docs/
    cp -r $more_rdf/* $publishRepositoryFolder/docs/
    cp -r $site/*.html $publishRepositoryFolder/docs/
    cd $publishRepositoryFolder
    if [ -n "\$(git status -s)" ]; then
        git config --global user.email "$userEmail"
            git config --global user.name "$userName"
        rm -rf docs/
        mkdir docs
        cp -r ../$site/*.html docs/
        cp -r ../$more_rdf/* docs/
        cp -r ../$site/*.html docs/
        cp -r ../$more_rdf/* docs/
        git add -A
        git status
        git commit -m "update ontology"
        git push
    fi
    """
}

// TODO NEED SOME REAL REFACTORING
process publish{
    debug true
    container 'bitnami/git'
    stageInMode 'copy'
    errorStrategy 'retry'
    maxRetries 2

    input:
    path files
    val publishRepository
    path deployKey
    val userEmail
    val userName
    path known_hosts
    script:
    """
    eval \$(ssh-agent)
    chmod 600 $deployKey
    ssh-add $deployKey
    mkdir ~/.ssh
    cp $known_hosts ~/.ssh/known_hosts
    git clone $publishRepository repo
    mkdir -p repo/docs/ProcessOntology
    mkdir .docs
    cp -r $files .docs

    cp -r .docs/serializations/index.nt repo/docs/index.nt

    # cp -r .docs/**/*.* repo/docs/
    # cp -r .docs/*.html repo/docs/
    # cp -r .docs/*.ttl repo/docs/
    # cp -r .docs/*.txt repo/docs/
    # cp -r .docs/**/*.* repo/docs/ProcessOntology
    # cp -r .docs/*.html repo/docs/ProcessOntology
    # cp -r .docs/*.ttl repo/docs/ProcessOntology
    # cp -r .docs/*.txt repo/docs/ProcessOntology
    cd repo
    if [ -n "\$(git status -s)" ]; then
        git config --global user.email "$userEmail"
            git config --global user.name "$userName"
        rm -rf docs/
        mkdir -p docs/ProcessOntology
        cp -r ../.docs/**/*.* docs/
        cp -r ../.docs/*.html docs/
        cp -r ../.docs/*.ttl docs/
        cp -r ../.docs/*.txt docs/
        cp -r ../.docs/**/*.* docs/ProcessOntology
        cp -r ../.docs/*.html docs/ProcessOntology
        cp -r ../.docs/*.ttl docs/ProcessOntology
        cp -r ../.docs/*.txt docs/ProcessOntology
        git add -A
        git status
        git commit -m "update ontology"
        git push
    else
        echo "Nothing new to commit"
    fi
    """
}

// TODO NEED SOME REAL REFACTORING
process publishVersioning{
    debug true
    container 'bitnami/git'
    stageInMode 'copy'
    errorStrategy 'retry'
    maxRetries 2

    input:
    path files
    val publishRepository
    val publishBranch
    path deployKey
    val userEmail
    val userName
    path known_hosts
    script:
    """
    eval \$(ssh-agent)
    chmod 600 $deployKey
    ssh-add $deployKey
    mkdir ~/.ssh
    cp $known_hosts ~/.ssh/known_hosts
    git clone $publishRepository repo
    if [ -n "$publishBranch" ]; then
        cd repo
        git checkout $publishBranch
        cd ..
    fi
    mkdir -p repo/docs/ProcessOntology
    mkdir .docs
    cp -r $files .docs
    cp -r .docs/serializations/index.nt repo/ontology.nt
    cd repo
    if [ -n "\$(git status -s)" ]; then
        git config --global user.email "$userEmail"
            git config --global user.name "$userName"
        git add -A
        git status
        git commit -m "update versioning ontology"
        git push
    else
        echo "Nothing new to commit"
    fi
    """
}
/**
 * Wrap files to correct w3id structure
 *
 * @param fragments fragmented ontolgoy
 * @param description Number of characters in each row of header.
 *
 * @return list of filepath with correct location for w3id
 */
process wrap{

    """
    """
}
