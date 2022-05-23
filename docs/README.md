# Build docs locally for cp-demo

Prerequisites:
- [Sphinx](http://www.sphinx-doc.org/en/stable/install.html)
- Python

Procedure:

1.  Set up a `docs` virtual environment (venv). You only have to do this step once. On subsequent builds you simply activate your existing venv.

    1.  Create a `~/.virtualenvs` directory if it doesn't already exist

        ```
        mkdir -p ~/.virtualenvs
        ```

    1.  Create a virtual environment named `cp-demo-docs`.

        ```
        python3 -m venv ~/.virtualenvs/cp-demo-docs
        ```

1.  Source configs and activate your venv from within your local docs repository.

    ```
    source ./settings.sh && source ~/.virtualenvs/cp-demo-docs/bin/activate
    ```
    **Tip:** If you are using `zsh` run `autoload bashcompinit; bashcompinit` so that you can source the `settings.sh` file.

1. Install dependencies with helper script.

    ```
    ./setup-venv.sh
    ```

1.  Build the docs.

    - Build the docs (live reloading pages). After the build is complete, you can access the live view of the HTML pages at http://127.0.0.1:5500/.

      ```
      make livehtml
      ```
    - Build the docs (non-reloading pages). These pages will not automatically reload (you must re-run make html to see updates). This method builds a version of the site that does not include the full styling and CSS, but after the initial setup, takes less than 1 minute to build and is very useful for quickly testing code and formatting. This method won't produce "/current" endpoint and therefore version menus will not be displayed.

      ```
      make html
      ```
      
1.  After you are done, deactivate the virtual environment.

    ```
    deactivate
    ```

1. Preview your changes in staging environment -- see [internal documentation](https://confluentinc.atlassian.net/wiki/spaces/DOC/pages/1679671102/Docs+Pipeline+Quick+Start#DocsPipelineQuickStart-Createstagingenvironmentfordocs-platformremotecomponents)

    - Basically you make a pull request on https://github.com/confluentinc/docs-platform that changes the "cp_demo_BRANCH" variable in `docs-platform/settings.sh`
    - This will automatically kick off a continuous integration job and give a staging URL where you can preview the site.
    - Make sure there are no syntax warnings like `Bullet list ends without a blank line; unexpected unindent.` since those will be interpreted as errors by CI (undefined and unknown warnings are ok since those are usually Sphinx variables that are filled in at runtime)
