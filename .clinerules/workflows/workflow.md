[workflows]

[workflows.setup_new_feature]
steps = [
  "read docs/feature_guide.md",
  "create a new branch `feature/{{feature_name}}`",
  "generate directory structure under /frontend_flutter/features/{{feature_name}}",
  "scaffold UI and API hooks",
  "write minimal test suite in /tests",
  "commit and summarize work"
]

[workflows.fix_bug]
steps = [
  "locate bug in {{file_path}}",
  "analyze error logs or console output",
  "propose minimal diff patch",
  "apply fix",
  "run automated tests",
  "commit and document fix"
]

[workflows.optimize_module]
steps = [
  "read entire module {{module_path}}",
  "identify performance bottlenecks",
  "suggest async or parallelization improvements",
  "apply safe optimizations",
  "document optimization in /docs/performance_log.md"
]
