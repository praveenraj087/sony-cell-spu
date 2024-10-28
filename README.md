## Contribution Guideline
* Clone <br>
    https://github.com/iampkmone/ESE545-CELL-SPU.git
* Create a local feature branch : pattern - feature/<name_of_feature> <br>
    ```git checkout -b feature/<name_of_feature>``` <br>
    ```git push –set-upstream origin feature/<name_of_feature>``` // this should create the remote branch on github with same name as your local branch <br>
    Example: ```git checkout -b feature/add```
* One done coding commit the change and push to remote <br>
    ```git status`` // this will show the files you've changed </br>
    ```git diff <file_name> ```// this will show the changes  </br>
    ```git add <file_name>``` // this will stage file_name you changed for commit</br>
    ``` git commit -m "Commit Message" ```// this will commit the files you've staged and -m wil add a message which should be short description of your feature</br>
* Push your change to remote branch </br>
    ```git push ```// to push your changes

To pull from existing remote branch 
*   ```git checkout -b <branch_name> /remotes/origin/<branch_name> ```
*  Remaining step to add change and commit remains same