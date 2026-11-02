# Provider credentials and spending

AI development requires an available Provider or an authenticated coding CLI. Installing the Suite does not create a model account, grant API access or purchase credits. Without a model, the product pages and local discovery, monitoring and release validation remain available.

Use the authentication method supported by the Provider. A ChatGPT or Kimi subscription does not by itself grant API billing access. The Suite must not extract browser cookies or copy an OAuth session into a different service. A supported coding CLI may use its own official login on the trusted execution host.

Use a dedicated development API key. Keep credentials out of project files, prompts, Git, screenshots, downloads and diagnostic archives. Do not reuse production credentials as a default setup step. Updating or revoking a development credential must not change another application's configuration.

Before a billable test, choose an explicit currency budget, request limit and output limit. Provider connectivity and model discovery do not establish an unlimited spending authorization. A fallback to a paid Provider requires that Provider's own authorization and remaining budget. Missing credentials, unknown pricing, unavailable models and exhausted budgets must stop AI execution with an actionable explanation.

DeepSeek model IDs and capabilities must come from the official account's model list, not from an old example. Check [official model discovery](https://api-docs.deepseek.com/api/list-models/) and [current pricing](https://api-docs.deepseek.com/zh-cn/quick_start/pricing/) before a live test. Do not enable billable search or fetch tools implicitly. A local usage estimate is not the Provider's invoice; account-level balance changes may include other applications.

API access sends the selected prompt and source context to that Provider. Use synthetic or otherwise approved project data. Execution is for a trusted local user; process separation and Git worktrees do not establish a secure execution host for untrusted tenants.
