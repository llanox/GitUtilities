#!/bin/bash
# Based on http://gbayer.com/development/moving-files-from-one-git-repository-to-another-preserving-history/.

basePath=$(pwd)/temporary;
echo  "basePath: $basePath"

if [ -z $1 ]; then branchTarget="master"; else branchTarget=$1; fi
	echo  "branchTarget: $branchTarget"



if [ -z $2 ]; then branchOrigin="master"; else branchOrigin=$2; fi
	echo  "branchOrigin: $branchOrigin"
	

if [ -z $3 ]; then 
	 echo "Please, provide an url for origin repo"
 	 exit 1 
else 
	originRepoURL=$3 
fi

if [ -z $4 ]; then 
	 echo "Please, provide an url for target repo"
 	 exit 1 
else 
	targetRepoURL=$4 
fi

echo  "originRepoURL: $originRepoURL"
echo  "targetRepoURL: $targetRepoURL"


shift && shift && shift && shift

#Directories that we're going to copy into our new repo
dirsTocopy=( "$@" )


if [ ${#dirsTocopy[@]} -eq 0 ]; then 
	 echo "Please, provide directories to copy"
 	 exit 1 
fi

echo  "Directories to copy:"
printf "%s\n" "${dirsTocopy[@]}"

rm -rf $basePath
mkdir $basePath

#Creating a temporary folder for copy process
rm -rf $basePath/repoTargetTemp;
mkdir -p $basePath/repoTargetTemp;


cd $basePath/repoTargetTemp;
echo "cloning..."
echo "git clone -b $branchTarget $targetRepoURL temp-repo";
git clone -b $branchTarget $targetRepoURL temp-repo;
#reset all commits
# cd temp-repo;
# git init;
# touch README;
# git add .;
# git commit -m 'Initial commit';
# git remote add origin $targetRepoURL;
# git push --force;
# cd ..;

cd ..;
rm -rf $basePath/repoOriginTemp;
mkdir -p $basePath/repoOriginTemp;
#TODO task to run on origin repo

cd $basePath/repoOriginTemp;
echo "cloning..."
echo "git clone -b $branchOrigin $originRepoURL temp-repo";
git clone -b $branchOrigin $originRepoURL temp-repo;
cp -R $basePath/repoOriginTemp/temp-repo $basePath/repoOriginTemp/temp-repo-copy;


# for each directory to copy into target repo
for dir in "${dirsTocopy[@]}"
do
		cd $basePath/repoOriginTemp/temp-repo;
		echo "Moving  $dir from $originRepoURL into $targetRepoURL"

	
		git remote rm origin;
		shopt -s extglob
        rm  -rf !($dir)
		git filter-branch --subdirectory-filter $dir/ -- --all;
		mkdir -p $basePath/repoOriginTemp/temp-repo/$dir;
		#Remove configuration files
		rm -rf .classpath .project .gitignore .settings .springBeans; 
		mv * $basePath/repoOriginTemp/temp-repo/$dir;
		git add --all ./;
		git commit -m "filter-branch by $dir directory " ;
		cd $basePath/repoTargetTemp/temp-repo/;


#TODO task to run on target repo
		git remote rm branch_temp;
		git remote add branch_temp $basePath/repoOriginTemp/temp-repo/;
		git pull branch_temp $branchTarget;
		git remote rm branch_temp;
		echo "Pushing .... git push $targetRepoURL $branchTarget:$branchOrigin "
		git commit -a;
		git push origin $branchTarget:$branchOrigin;

		if [ $? -eq 0 ]; then
          echo "Pushing OK";
        else
          echo "Error pushing changes";
          exit 1 ;
        fi

        rm -rf $basePath/repoOriginTemp/temp-repo
        cp -R $basePath/repoOriginTemp/temp-repo-copy $basePath/repoOriginTemp/temp-repo;
done

echo "Finished process"
