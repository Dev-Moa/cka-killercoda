# Deployment Rollout - done

The exam facts from this exercise:

- `--record` is removed from kubectl — it no longer fills the CHANGE-CAUSE column.
- Use the `kubernetes.io/change-cause` annotation on the Deployment instead.
- The annotation lives on the Deployment object, not on each revision, so the second annotate needs `--overwrite` or it fails with "annotation already exists".
- `kubectl rollout undo` creates a NEW revision with the old spec — after an undo the history shows revisions 1 and 3, not 1 and 2.
- `kubectl set image deployment/webapp nginx=nginx:1.29 -n exercise-06` updates the image.
- `kubectl rollout status deployment/webapp -n exercise-06` waits for the rollout to finish.
- `kubectl rollout history deployment/webapp -n exercise-06` lists the revisions; `kubectl rollout undo` rolls back one revision.

The exercise is based on the rolling updates and rollbacks note in `notes/4-application-lifecycle-management/35` and exercise 06 in `cka-prep/exercises/1-workloads/`.
