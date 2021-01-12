# Build docs locally for cp-demo

Prerequisites:
- [Sphinx](http://www.sphinx-doc.org/en/stable/install.html)
- Python

Procedure:

1.  Set up a `docs` virtual environment (venv). You only have to do this step once. On subsequent builds you simply activate your existing venv.

    1.  Create a `~/.virtualenvs` directory and navigate into it.

        ```
        mkdir ~/.virtualenvs
        cd ~/.virtualenvs
        ```

    1.  Create a virtual environment named `docs`.

        ```
        python3 -m venv docs    
        ```

1.  Change directories to your local docs repository and check out the branch you want to build (`git checkout <branch>`).

1.  Source configs and activate your venv from within your local docs repository.

    ```
    source ./settings.sh && source ~/.virtualenvs/docs/bin/activate
    ```
    **Tip:** If you are using `zsh` run `autoload bashcompinit; bashcompinit` so that you can source the `settings.sh` file.

1.  Use `pip install` to install the local `requirements.txt`.

    ```
    pip install -r requirements.txt
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