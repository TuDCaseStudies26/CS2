# Case Studies 2

## Clone Repo

First go to the directory where you want your repo and clone it:
```
git clone https://github.com/TuDCaseStudies26/CS2.git
cd CS2
```
or if you are using ssh
```
git clone git@github.com:TuDCaseStudies26/CS2.git
cd CS2
```

## Install uv
We manage python version, dependencies and the virtual environment with uv.
You can find the installation guide under [https://docs.astral.sh/uv/getting-started/installation/].

## Create environment and install packages
Run the following command to install the virtual environment and relevant packages:
```
uv sync
```

If you want to add dependencies, you can do it with:
```
uv add <dependency>
```

After pulling changes from the repo, I recommend to sync, so that you have all important dependencies:
```
uv sync
```

## How to contribute
We use a feature branch workflow. The main branch is protected against direct changes.
So the workflow should look like this:
```
git switch main
git pull
```
Then create a new branch:
```
git switch -c feature/nameOfFeature
```
And if you want to commit:
```
git add <files>
git commit -m "commit message"
git push -u origin feature/nameOfFeature
```
After that go to GitHub or use the GitHub app to open a pull request.
The pull request needs at least one other person to merge it with the main branch.
To keep it clean and linear switch back to main and delete the feature branch with:
```
git switch main
git branch -d feature/nameOfFeature
```
