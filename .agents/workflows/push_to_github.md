---
description: Push Fatih Client changes to GitHub
---

# Push Fatih Client changes to GitHub

This is a strict project rule established by the user to ensure that the Fatih Client software version displayed on the smart boards gets updated correctly automatically every single time code is pushed. 
If the user ever asks you to push code to github, or to commit and push changes, you MUST ALWAYS follow these exact steps:

1. In the `c:\Github\Pardus_Tahta` root directory, execute the `increment_version.py` script.
   ```bash
   python increment_version.py
   ```
2. Check the output of the script to ensure the version (e.g. `V1.00.01`) was successfully incremented (e.g. `V1.00.02`).
3. Add ALL changes including the newly updated `fatih_projesi_python\client\version.txt` to the Git stage.
4. Commit the changes with an appropriate message.
5. Push the changes to GitHub.

DO NOT skip step 1. The user explicitly required this so they do not have to remind the AI every session. Every push MUST have a version bump.
