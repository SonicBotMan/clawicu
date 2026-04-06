import type { Issue } from "@/types";

export const ISSUES: Issue[] = [
  {
    id: "config-corruption",
    slug: "config-corruption",
    title: "Config File Corruption",
    description:
      "The config.json5 file contains invalid JSON5 syntax, preventing OpenClaw from starting. This is the most common fatal error and can be caused by manual edits, failed upgrades, or truncated writes.",
    icon: "FileWarning",
    severity: "fatal",
    diagnosis:
      "Run `openclaw doctor` and look for JSON parse errors, or manually inspect ~/.openclaw/config.json5 for trailing commas, unclosed braces, or commented-out fields that break the parser.",
    steps: [
      "Back up the current config: `cp ~/.openclaw/config.json5 ~/.openclaw/config.json5.bak`",
      "Validate JSON5 syntax using an online JSON5 linter or `node -e \"require('json5').parse(require('fs').readFileSync('~/.openclaw/config.json5','utf8'))\"`",
      "If a backup exists at config.json5.bak, compare and restore the last known good version",
      "Fix specific syntax errors \u2014 look for trailing commas, missing quotes, or invalid escape sequences",
      "Run `openclaw doctor` to verify the config loads correctly after the fix",
    ],
    relatedChecks: ["check-config", "check-config-schema"],
    relatedRepairs: ["repair-config", "repair-config-field"],
  },
  {
    id: "plugin-failures",
    slug: "plugin-failures",
    title: "Plugin Manifest Errors",
    description:
      "One or more installed plugins have broken manifests or fail to load, causing runtime errors or preventing OpenClaw from starting. Often occurs after upgrading OpenClaw without updating plugins.",
    icon: "Puzzle",
    severity: "warn",
    diagnosis:
      "Check OpenClaw logs for plugin load errors, or run `openclaw plugins list` to see which plugins fail to enumerate. Look for missing manifest.json files or schema mismatches in ~/.openclaw/plugins/.",
    steps: [
      "List all plugins: `openclaw plugins list` and note any that show errors",
      "Check each plugin directory under ~/.openclaw/plugins/ for a valid manifest.json",
      "Disable problematic plugins by renaming their directory with a `.disabled` suffix",
      "Re-enable plugins one at a time, testing with `openclaw doctor` after each",
      "Update or reinstall plugins that are incompatible with your current OpenClaw version",
    ],
    relatedChecks: ["check-plugins"],
    relatedRepairs: ["repair-plugins"],
  },
  {
    id: "gateway-crash",
    slug: "gateway-crash",
    title: "Gateway Not Running",
    description:
      "The OpenClaw gateway process has crashed or failed to start on port 18789. This makes all agent channels unreachable even though the rest of the system may be healthy.",
    icon: "WifiOff",
    severity: "fatal",
    diagnosis:
      "Check if the gateway is listening: `curl -s http://localhost:18789/health` or `lsof -i :18789`. Inspect gateway logs in ~/.openclaw/logs/ for crash traces or OOM kills.",
    steps: [
      "Check if the process exists: `ps aux | grep openclaw` or `pgrep -f openclaw-gateway`",
      "Review recent gateway logs in ~/.openclaw/logs/ for the crash reason",
      "Kill any zombie gateway processes: `pkill -f openclaw-gateway`",
      "Restart the gateway: `openclaw gateway start` or the appropriate install-method command",
      "Verify it is running: `curl -s http://localhost:18789/health` should return 200",
    ],
    relatedChecks: ["check-gateway"],
    relatedRepairs: ["repair-gateway"],
  },
  {
    id: "daemon-issues",
    slug: "daemon-issues",
    title: "Daemon Service Not Installed",
    description:
      "The OpenClaw daemon (launchd on macOS, systemd on Linux) is not registered as a system service. This means OpenClaw will not auto-start on boot and background operations may fail.",
    icon: "ShieldAlert",
    severity: "warn",
    diagnosis:
      "On macOS: `launchctl list | grep openclaw`. On Linux: `systemctl --user status openclaw`. If neither shows the service, it is not installed.",
    steps: [
      "Verify the service is missing: `launchctl list | grep openclaw` (macOS) or `systemctl --user status openclaw` (Linux)",
      "Check for an existing plist/unit file that was not loaded",
      "Run `openclaw daemon install` to register the service with your system's service manager",
      "Start the daemon immediately: `openclaw daemon start`",
      "Verify auto-start works: reboot (optional) or `openclaw daemon status`",
    ],
    relatedChecks: ["check-daemon"],
    relatedRepairs: ["repair-daemon"],
  },
  {
    id: "credential-problems",
    slug: "credential-problems",
    title: "Missing API Credentials",
    description:
      "Provider API keys are missing or empty in the credentials store. OpenClaw cannot connect to any AI provider without valid credentials, making all agent requests fail.",
    icon: "KeyRound",
    severity: "warn",
    diagnosis:
      "Check ~/.openclaw/credentials/ for empty or missing key files. Run `openclaw doctor` \u2014 it will report which providers have no configured credentials.",
    steps: [
      "Run `openclaw doctor` to see which providers are missing credentials",
      "Locate your API keys from each provider's dashboard (OpenAI, Anthropic, Google, etc.)",
      "Set credentials: `openclaw onboard` for interactive setup, or set environment variables like `OPENAI_API_KEY`",
      "Verify credentials are stored: check that files in ~/.openclaw/credentials/ are non-empty",
      "Test connectivity: run a simple prompt through the provider to confirm the key works",
    ],
    relatedChecks: ["check-credentials"],
    relatedRepairs: ["repair-credentials"],
  },
  {
    id: "port-conflicts",
    slug: "port-conflicts",
    title: "Port 18789 Occupied",
    description:
      "Another process is already using port 18789, preventing the OpenClaw gateway from binding. This commonly happens when a previous OpenClaw instance did not shut down cleanly or another service claims the same port.",
    icon: "Network",
    severity: "fatal",
    diagnosis:
      "Run `lsof -i :18789` or `ss -tlnp | grep 18789` to see which process holds the port. Compare the PID with `pgrep -f openclaw` to determine if it is a stale OpenClaw process or a foreign service.",
    steps: [
      "Identify the process: `lsof -i :18789` (macOS) or `ss -tlnp | grep 18789` (Linux)",
      "If it is a stale OpenClaw process, kill it: `kill <PID>` (or `kill -9` if unresponsive)",
      "If it is another service, decide whether to stop that service or reconfigure OpenClaw's port",
      "To change OpenClaw's port, edit the `port` field in ~/.openclaw/config.json5",
      "Restart the gateway and verify: `curl -s http://localhost:<port>/health`",
    ],
    relatedChecks: ["check-port"],
    relatedRepairs: ["repair-port"],
  },
  {
    id: "network-timeout",
    slug: "network-timeout",
    title: "Network Timeout",
    description:
      "OpenClaw agent cannot connect to the gateway due to network timeout or firewall rules blocking communication between components.",
    icon: "Network",
    severity: "warn",
    diagnosis:
      "Check connectivity with `curl -s --connect-timeout 5 http://localhost:18789/health`. If using a remote gateway, verify firewall rules allow traffic on port 18789. DNS issues can be diagnosed with `nslookup` or `dig`.",
    steps: [
      "Test local connectivity: `curl -s http://localhost:18789/health`",
      "Check firewall rules: `sudo iptables -L -n` (Linux) or System Preferences > Security (macOS)",
      "If using DNS, verify resolution: `nslookup your-gateway-host`",
      "Check for network latency: `ping -c 5 your-gateway-host`",
      "For remote deployments, verify security group rules allow inbound traffic on the gateway port",
    ],
    relatedChecks: ["check-gateway", "check-port"],
    relatedRepairs: ["repair-gateway", "repair-port"],
  },
  {
    id: "memory-leak",
    slug: "memory-leak",
    title: "Memory Leak",
    description:
      "OpenClaw daemon memory usage grows continuously until the process is killed by the OOM killer. This degrades performance over time and causes unexpected crashes.",
    icon: "Cpu",
    severity: "fatal",
    diagnosis:
      "Monitor memory with `top -pid $(pgrep -f openclaw)` or `ps aux | grep openclaw`. If RSS grows steadily over hours, a memory leak is likely. Check ~/.openclaw/logs/ for OOM kill messages.",
    steps: [
      "Check current memory usage: `ps -o rss,vsz,pid,comm -p $(pgrep -f openclaw)`",
      "Review logs for OOM messages: `grep -i 'oom\\|killed' ~/.openclaw/logs/*`",
      "Disable all plugins and restart to isolate: `openclaw plugins disable-all`",
      "Re-enable plugins one at a time while monitoring memory to find the culprit",
      "If leak persists with no plugins, upgrade OpenClaw to the latest version",
    ],
    relatedChecks: ["check-gateway", "check-plugins"],
    relatedRepairs: ["repair-plugins", "repair-gateway"],
  },
  {
    id: "disk-space-full",
    slug: "disk-space-full",
    title: "Disk Space Full",
    description:
      "OpenClaw cannot write logs, session data, or state files due to insufficient disk space on the volume hosting ~/.openclaw/.",
    icon: "HardDrive",
    severity: "fatal",
    diagnosis:
      "Check available space: `df -h ~/.openclaw/`. Check log sizes: `du -sh ~/.openclaw/logs/`. Large session histories can also consume significant space.",
    steps: [
      "Check disk usage: `df -h` and `du -sh ~/.openclaw/*`",
      "Clear old logs: `find ~/.openclaw/logs/ -mtime +30 -delete`",
      "Clear old sessions: `find ~/.openclaw/sessions/ -mtime +7 -delete`",
      "Set up log rotation in config.json5: add `logRotation: { maxFiles: 7, maxSize: '50mb' }`",
      "If still low on space, consider moving ~/.openclaw/ to a larger volume",
    ],
    relatedChecks: ["check-disk"],
    relatedRepairs: ["repair-config"],
  },
  {
    id: "permission-denied",
    slug: "permission-denied",
    title: "Permission Denied",
    description:
      "OpenClaw cannot access configuration files, state directories, or credentials due to incorrect file permissions or SELinux/AppArmor restrictions.",
    icon: "Lock",
    severity: "warn",
    diagnosis:
      "Check ownership: `ls -la ~/.openclaw/`. If files are owned by root or another user, OpenClaw cannot write to them. On Linux, check SELinux: `getenforce` and AppArmor: `aa-status`.",
    steps: [
      "Check file ownership: `ls -laR ~/.openclaw/ | head -50`",
      "Fix ownership: `sudo chown -R $(whoami) ~/.openclaw/`",
      "Fix permissions: `chmod -R u+rwX ~/.openclaw/`",
      "On Linux with SELinux: `sudo restorecon -Rv ~/.openclaw/`",
      "If running as a dedicated user, ensure the user owns all files: `sudo -u openclaw openclaw doctor`",
    ],
    relatedChecks: ["check-state-dir", "check-config"],
    relatedRepairs: ["repair-config"],
  },
  {
    id: "database-locked",
    slug: "database-locked",
    title: "Database Locked",
    description:
      "OpenClaw's SQLite database is locked by another process, preventing writes to session state, plugin data, or configuration cache.",
    icon: "Database",
    severity: "warn",
    diagnosis:
      "Check for lock files: `ls -la ~/.openclaw/*.db-journal ~/.openclaw/*.db-wal`. Multiple OpenClaw processes or a previous crash can leave locks behind.",
    steps: [
      "Check for multiple processes: `ps aux | grep openclaw`",
      "Stop all OpenClaw processes: `pkill -f openclaw`",
      "Remove stale lock files: `rm -f ~/.openclaw/*.db-journal ~/.openclaw/*.db-wal ~/.openclaw/*.db-shm`",
      "Restart OpenClaw: `openclaw gateway start`",
      "If the database is corrupted, restore from backup: `cp ~/.openclaw/state.db.bak ~/.openclaw/state.db`",
    ],
    relatedChecks: ["check-gateway", "check-sessions"],
    relatedRepairs: ["repair-gateway"],
  },
  {
    id: "ssl-certificate-expired",
    slug: "ssl-certificate-expired",
    title: "SSL Certificate Expired",
    description:
      "The OpenClaw gateway's SSL/TLS certificate has expired, causing HTTPS connections to be rejected by clients and browsers.",
    icon: "ShieldAlert",
    severity: "fatal",
    diagnosis:
      "Check certificate expiry: `openssl x509 -enddate -noout -in ~/.openclaw/certs/server.crt`. Also verify system time is correct: `date` \u2014 incorrect clocks can cause false expiry.",
    steps: [
      "Check certificate expiry date: `openssl x509 -enddate -noout -in ~/.openclaw/certs/server.crt`",
      "Verify system time is correct: `date` and `ntpdate -q pool.ntp.org`",
      "If using Let's Encrypt, renew: `certbot renew --cert-name openclaw`",
      "For self-signed certs, regenerate: `openclaw gateway cert regenerate`",
      "Restart the gateway after certificate renewal",
    ],
    relatedChecks: ["check-gateway", "check-config"],
    relatedRepairs: ["repair-gateway"],
  },
  {
    id: "api-rate-limit",
    slug: "api-rate-limit",
    title: "API Rate Limit Exceeded",
    description:
      "OpenClaw is sending too many requests to AI provider APIs within a short time window, causing 429 responses and failed agent interactions.",
    icon: "Gauge",
    severity: "info",
    diagnosis:
      "Check logs for 429 responses: `grep -i '429\\|rate limit' ~/.openclaw/logs/*`. The `openclaw doctor` command also reports rate limit warnings.",
    steps: [
      "Check recent 429 errors: `grep '429' ~/.openclaw/logs/gateway.log | tail -20`",
      "Add request delays in config.json5: `apiThrottle: { minInterval: 500 }`",
      "Enable response caching to reduce redundant API calls",
      "If using a provider with usage tiers, consider upgrading your plan",
      "Distribute load across multiple API keys or providers",
    ],
    relatedChecks: ["check-credentials", "check-gateway"],
    relatedRepairs: ["repair-config-field"],
  },
  {
    id: "version-mismatch",
    slug: "version-mismatch",
    title: "Version Mismatch",
    description:
      "OpenClaw agent, gateway, and CLI are running different versions, causing protocol incompatibility and communication errors between components.",
    icon: "RefreshCcw",
    severity: "warn",
    diagnosis:
      "Check versions: `openclaw --version`, `openclaw gateway version`, and compare with `cat ~/.openclaw/VERSION`. Mismatches after partial upgrades are the most common cause.",
    steps: [
      "Check all component versions: `openclaw --version` and `openclaw gateway version`",
      "Compare with the expected version from the release notes",
      "Update all components together: `npm update -g openclaw && openclaw gateway restart`",
      "For Docker: pull the latest image and recreate the container",
      "Verify compatibility after upgrade: `openclaw doctor`",
    ],
    relatedChecks: ["check-version", "check-binary"],
    relatedRepairs: ["repair-downgrade"],
  },
  {
    id: "startup-failure",
    slug: "startup-failure",
    title: "Startup Failure",
    description:
      "OpenClaw daemon fails to start on system boot or after a manual restart. The service enters a failed state with a non-zero exit code.",
    icon: "Power",
    severity: "fatal",
    diagnosis:
      "Check service logs: `journalctl --user -u openclaw` (Linux) or `log show --predicate 'process == \"openclaw\"'` (macOS). Common causes include missing dependencies, port conflicts, and configuration errors.",
    steps: [
      "Check service status: `systemctl --user status openclaw` (Linux) or `launchctl list | grep openclaw` (macOS)",
      "Review detailed logs: `journalctl --user -u openclaw -n 50` or check ~/.openclaw/logs/",
      "Verify all dependencies are met: Node.js >= 22.12, disk space, network access",
      "Check for port conflicts: `lsof -i :18789`",
      "Try manual start to see the error: `openclaw gateway start --foreground`",
    ],
    relatedChecks: ["check-binary", "check-node", "check-gateway", "check-port"],
    relatedRepairs: ["repair-gateway", "repair-daemon"],
  },
  {
    id: "pairing-required",
    slug: "pairing-required",
    title: "Pairing Not Approved",
    description:
      "A sender or device has requested pairing but is waiting for approval. Messages from unapproved senders are silently ignored until pairing is approved.",
    icon: "UserCheck",
    severity: "warn",
    diagnosis:
      "Check pending pairing requests: `openclaw pairing list --channel <channel>`. Look for `pairing request` in logs. In groups, also check if mention patterns are configured correctly.",
    steps: [
      "List pending pairing requests: `openclaw pairing list --channel <channel>`",
      "Approve the sender: `openclaw pairing approve --channel <channel> --account <id>`",
      "For DMs, set policy to open: add `channels.<channel>.dmPolicy: \"open\"` to config",
      "For groups, ensure the sender is in the allowlist or set `requireMention: false`",
      "Test by sending another message after approval",
    ],
    relatedChecks: ["check-gateway", "check-channels"],
    relatedRepairs: ["repair-gateway"],
  },
  {
    id: "mention-required",
    slug: "mention-required",
    title: "Mention Required in Group",
    description:
      "OpenClaw ignores messages in group chats unless the bot is @mentioned. This is a security feature to prevent the bot from responding to every message in a group.",
    icon: "MessageSquare",
    severity: "warn",
    diagnosis:
      "Check logs for `drop guild message (mention required`. Verify group configuration: `openclaw config get channels` and look for `mentionPatterns` or `requireMention` settings.",
    steps: [
      "Check group channel config: `openclaw config get channels`",
      "Update mention settings in config.json5 to add your group or disable mention requirement: `channels.<channel>.groups.\"*\".requireMention: false`",
      "Or add your group ID to mention patterns: `channels.<channel>.groups.\"<group-id>\".requireMention: true`",
      "Restart the gateway after config changes: `openclaw gateway restart`",
      "Test by @mentioning the bot in the group",
    ],
    relatedChecks: ["check-gateway", "check-channels"],
    relatedRepairs: ["repair-gateway"],
  },
  {
    id: "channel-auth-failure",
    slug: "channel-auth-failure",
    title: "Channel Authentication Failed",
    description:
      "A channel (Discord, Telegram, Slack, etc.) failed to authenticate or lost authorization. Bot token may be expired or revoked.",
    icon: "ShieldOff",
    severity: "fatal",
    diagnosis:
      "Check channel status: `openclaw channels status --probe`. Look for `401`, `403`, `missing_scope`, or `not_in_channel` in logs. Verify the bot token has required permissions.",
    steps: [
      "Run channel probe: `openclaw channels status --probe`",
      "Check logs for auth errors: `grep -E '401|403|Forbidden|missing_scope' ~/.openclaw/logs/*`",
      "Verify bot token: Discord requires bot token, Telegram needs API ID/hash, Slack needs workspace token",
      "For Discord: Re-add the bot to the server with correct permissions",
      "For Telegram: Regenerate session via `openclaw channels configure telegram`",
      "Restart gateway and re-test: `openclaw gateway restart`",
    ],
    relatedChecks: ["check-gateway", "check-credentials", "check-channels"],
    relatedRepairs: ["repair-credentials", "repair-gateway"],
  },
  {
    id: "dashboard-connect-failed",
    slug: "dashboard-connect-failed",
    title: "Dashboard Cannot Connect",
    description:
      "The OpenClaw Control UI (browser dashboard) fails to connect to the gateway. This is usually an auth token mismatch or origin allowlist issue.",
    icon: "LayoutDashboard",
    severity: "warn",
    diagnosis:
      "Check gateway status: `openclaw gateway status`. Look for `origin not allowed`, `device identity required`, or `AUTH_TOKEN_MISMATCH` in logs.",
    steps: [
      "Get the auth token: `openclaw config get gateway.auth.token`",
      "Open the dashboard URL shown in `openclaw gateway status`",
      "Paste the token when prompted in the dashboard",
      "If origin error: add your browser origin to `gateway.controlUi.allowedOrigins` in config",
      "For device auth issues: `openclaw devices list` and approve/rotate stale tokens",
      "Try connecting from localhost if remote access is not configured",
    ],
    relatedChecks: ["check-gateway", "check-config"],
    relatedRepairs: ["repair-gateway"],
  },
  {
    id: "cron-not-running",
    slug: "cron-not-running",
    title: "Cron Job Not Executing",
    description:
      "Scheduled cron jobs are not running at their specified times. The cron scheduler may be disabled or the job configuration is invalid.",
    icon: "Clock",
    severity: "warn",
    diagnosis:
      "Check cron status: `openclaw cron status` and `openclaw cron list`. Look for `scheduler disabled` or empty job list.",
    steps: [
      "Check cron scheduler status: `openclaw cron status`",
      "List all cron jobs: `openclaw cron list`",
      "View recent runs: `openclaw cron runs --id <jobId> --limit 10`",
      "Enable cron if disabled: `openclaw config set cron.enabled true`",
      "Check heartbeat settings if using heartbeat-based triggers",
      "Verify the job's schedule syntax is valid (cron format)",
    ],
    relatedChecks: ["check-gateway", "check-config"],
    relatedRepairs: ["repair-gateway"],
  },
  {
    id: "heartbeat-skipped",
    slug: "heartbeat-skipped",
    title: "Heartbeat Not Sent",
    description:
      "The scheduled heartbeat message is not being sent. This can happen during quiet hours, when there are active requests in flight, or when the heartbeat file is empty.",
    icon: "HeartOff",
    severity: "info",
    diagnosis:
      "Check heartbeat status: `openclaw system heartbeat last`. Look for skip reasons like `quiet-hours`, `requests-in-flight`, `empty-heartbeat-file`, or `no-tasks-due` in logs.",
    steps: [
      "View last heartbeat: `openclaw system heartbeat last`",
      "Check skip reasons in logs: `grep heartbeat ~/.openclaw/logs/*`",
      "Ensure HEARTBEAT.md contains actual task items, not just headers",
      "Check quiet hours config if `quiet-hours` is the skip reason",
      "If `requests-in-flight`: wait for pending requests to complete",
      "For `no-tasks-due`: add tasks with due dates to HEARTBEAT.md",
    ],
    relatedChecks: ["check-gateway", "check-config"],
    relatedRepairs: ["repair-gateway"],
  },
  {
    id: "browser-unavailable",
    slug: "browser-unavailable",
    title: "Browser Tool Not Working",
    description:
      "The browser automation tool fails to launch Chrome or connect via CDP. This prevents screenshot, web scraping, and browser-based automation.",
    icon: "Globe",
    severity: "warn",
    diagnosis:
      "Check browser status: `openclaw browser status`. Look for `unknown command browser`, `Failed to start Chrome`, or `CDP port` errors in logs.",
    steps: [
      "Verify browser plugin is loaded: `openclaw browser status`",
      "Ensure `browser` is in `plugins.allow` in config if allowlist is set",
      "Check Chrome is installed: Chrome or Chromium must be available",
      "For remote CDP: verify the CDP URL is reachable from gateway host",
      "Restart browser: `openclaw browser stop && openclaw browser start`",
      "Check firewall: ensure localhost CDP ports are not blocked",
    ],
    relatedChecks: ["check-gateway", "check-plugins"],
    relatedRepairs: ["repair-gateway", "repair-plugins"],
  },
  {
    id: "exec-approval-required",
    slug: "exec-approval-required",
    title: "Exec Command Requires Approval",
    description:
      "A shell command that was previously allowed now requires manual approval. This happens when exec security policy tightens or a new session is created.",
    icon: "Terminal",
    severity: "warn",
    diagnosis:
      "Check exec config: `openclaw config get tools.exec.security` and `tools.exec.ask`. Look for `Approval required` or `SYSTEM_RUN_DENIED` in logs.",
    steps: [
      "Check current exec settings: `openclaw config get tools.exec`",
      "Set to allowlist mode for less friction: `openclaw config set tools.exec.security allowlist`",
      "Disable approval prompt: `openclaw config set tools.exec.ask off`",
      "Add commands to allowlist: `openclaw config set tools.exec.allowlist '[\"git\", \"npm\", \"node\"]'`",
      "Restart gateway: `openclaw gateway restart`",
      "Approve pending command: `openclaw approve <command>`",
    ],
    relatedChecks: ["check-gateway", "check-config"],
    relatedRepairs: ["repair-gateway"],
  },
  {
    id: "plugin-sdk-incompatibility",
    slug: "plugin-sdk-incompatibility",
    title: "Plugin SDK Incompatibility",
    description:
      "A plugin uses an outdated OpenClaw SDK API (e.g. `api.config.get is not a function`) or the `plugin-sdk` module is missing entirely. This usually appears after upgrading OpenClaw without updating installed plugins, causing the gateway to hang or emit unhandled promise rejections.",
    icon: "Puzzle",
    severity: "fatal",
    diagnosis:
      "Run `openclaw doctor` and look for `TypeError: api.config.get is not a function`, `ERR_MODULE_NOT_FOUND: plugin-sdk`, or `Unhandled promise rejection`. The stack trace includes `at activate (...)` pointing to the broken plugin file.",
    steps: [
      "Identify the offending plugin from the stack trace: look for `at activate (/path/to/plugin.js:...)` in doctor output",
      "For missing plugin-sdk: `cd ~/.openclaw/extensions/<plugin>/ && npm install --prefer-offline`",
      "If npm install fails, disable the plugin: `mv ~/.openclaw/extensions/<plugin>/dist-node/index.js ~/.openclaw/extensions/<plugin>/dist-node/index.js.disabled`",
      "Add the plugin to deny list to prevent auto-load: `openclaw config set plugins.deny '[\"<plugin-id>\"]'`",
      "Verify the fix: run `openclaw doctor` again — the TypeError should no longer appear",
      "To re-enable later: update the plugin to a version compatible with your OpenClaw version",
    ],
    relatedChecks: ["check-plugins-sdk", "check-plugins"],
    relatedRepairs: ["repair-plugins-sdk", "repair-plugins"],
  },
  {
    id: "channel-policy-issues",
    slug: "channel-policy-issues",
    title: "Channel Policy Blocking Messages",
    description:
      "Discord (or other channel) messages are silently ignored because the channel policy is too restrictive. The most common case: `groupPolicy: 'allowlist'` combined with `requireMention: true` causes direct messages to the bot to never receive a response.",
    icon: "ShieldAlert",
    severity: "warn",
    diagnosis:
      "Check config: `openclaw config get channels.discord`. If `groupPolicy` is `allowlist` and any guild has `requireMention: true`, DMs will be dropped. Also check `allowFrom` — if it is empty and policy is not `open`, no users can message the bot.",
    steps: [
      "Inspect current policy: `openclaw config get channels.discord`",
      "To allow DMs from everyone, set groupPolicy to open: `openclaw config set channels.discord.groupPolicy open`",
      "To keep allowlist but fix DMs, remove `requireMention` from the affected guild config",
      "If `allowFrom` is empty, add user IDs: `openclaw config set channels.discord.allowFrom '[\"<user-id>\"]'` or change policy to `open`",
      "After changing config, restart the gateway: `systemctl --user restart openclaw-gateway` (Linux) or `openclaw daemon stop && openclaw daemon start` (macOS)",
      "Test by sending a direct message to the bot",
    ],
    relatedChecks: ["check-channel-policy"],
    relatedRepairs: ["repair-channel-policy"],
  },
];

export function getIssueBySlug(slug: string): Issue | undefined {
  return ISSUES.find((issue) => issue.slug === slug);
}

export function getIssueById(id: string): Issue | undefined {
  return ISSUES.find((issue) => issue.id === id);
}
