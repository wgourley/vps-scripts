# Update-safe local patches

For apps installed from git (AVideo, and many PHP apps) where you have had to edit a few of the app's own files.

`git-patch-update.sh` saves your edits as a patch, pulls the update, and re-applies them, or warns you if upstream changed the same lines.

## Tips

- Keep `FILES` to the files you really changed. Everything else should live outside the app (plugins, config files, injected CSS/JS).
- **When upstream fixes something you had patched yourself, remove that file from `FILES` and regenerate the patch before updating.** Otherwise the patch no longer applies, and because it applies as one unit, your *other* fixes are skipped too.
- Report the bug upstream. The best local patch is one you can delete.
