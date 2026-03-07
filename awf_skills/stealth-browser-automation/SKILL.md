---
name: stealth-browser-automation
description: Anti-detect browser automation with Camoufox + Playwright — fingerprint evasion, proxy rotation, session persistence, human-like behavior, CAPTCHA handling, and account warming protocols. For social media automation and data collection.
---

# Stealth Browser Automation — Camoufox + Playwright

Use this skill for browser automation that must evade anti-bot detection systems.

---

## 1. Camoufox Setup (Rust → Python Bridge)

### Launch Camoufox from Rust
```rust
use tokio::process::Command;

pub async fn launch_camoufox(profile: &BrowserProfile) -> Result<BrowserInstance, AppError> {
    let mut cmd = Command::new("python3")
        .args(["-c", &format!(r#"
import asyncio
from camoufox.async_api import AsyncCamoufox

async def main():
    async with AsyncCamoufox(
        headless="virtual",
        humanize=True,
        os=("{os}"),
        proxy={{
            "server": "{proxy_server}",
            "username": "{proxy_user}",
            "password": "{proxy_pass}",
        }},
        geoip=True,
        persistent_context="{profile_dir}",
    ) as browser:
        page = browser.contexts[0].pages[0]
        # Export CDP endpoint for Rust to connect
        print(f"CDP:{{browser.contexts[0]._impl_obj._channel._connection._transport._ws_endpoint}}")
        await asyncio.Event().wait()

asyncio.run(main())
"#,
            os = profile.os,
            proxy_server = profile.proxy.server,
            proxy_user = profile.proxy.username,
            proxy_pass = profile.proxy.password,
            profile_dir = profile.data_dir,
        )])
        .stdout(std::process::Stdio::piped())
        .spawn()?;

    // Parse CDP endpoint from stdout
    // Connect via playwright-rust...
    Ok(BrowserInstance { process: cmd, cdp_url })
}
```

---

## 2. Fingerprint Configuration

### Profile Generation
```python
from browserforge.fingerprints import FingerprintGenerator

fg = FingerprintGenerator(
    browser="firefox",
    os=("windows", "macos"),
    locale="en-US",
    screen={"min_width": 1280, "max_width": 1920},
)

# Generate consistent, realistic fingerprint
fingerprint = fg.generate()

# Includes: navigator, screen, WebGL, Canvas, AudioContext, fonts
```

### Key Anti-Detection Features
| Feature | Technique | Level |
|---------|-----------|:-----:|
| **User-Agent** | Matches real Firefox distribution | C++ |
| **WebGL** | Spoofed renderer/vendor strings | C++ |
| **Canvas** | Noise injection in pixel data | C++ |
| **AudioContext** | Modified frequency response | C++ |
| **Screen** | Consistent resolution + DPR | C++ |
| **Fonts** | OS-appropriate font list | C++ |
| **WebRTC** | SDP/ICE candidate spoofing | Protocol |
| **navigator.webdriver** | Hidden from detection | C++ |

---

## 3. Session Persistence

```python
# Persistent context — maintains cookies, localStorage, history
async with AsyncCamoufox(
    persistent_context="data/profiles/youtube-farm-01",
    # All cookies/session data saved between restarts
) as browser:
    page = browser.contexts[0].pages[0]
    # Check if already logged in
    await page.goto("https://www.youtube.com")
    if await page.query_selector('[aria-label="Sign in"]'):
        # Need to re-auth
        await perform_login(page, credentials)
    else:
        # Already logged in from previous session
        pass
```

---

## 4. Human-like Behavior

### Mouse Movement
```python
import random, asyncio

async def human_click(page, selector):
    element = await page.wait_for_selector(selector)
    box = await element.bounding_box()
    # Move to element with natural curve
    x = box["x"] + box["width"] * random.uniform(0.3, 0.7)
    y = box["y"] + box["height"] * random.uniform(0.3, 0.7)
    await page.mouse.move(x, y, steps=random.randint(15, 30))
    await asyncio.sleep(random.uniform(0.1, 0.3))
    await page.mouse.click(x, y)

async def human_type(page, selector, text):
    await page.click(selector)
    for char in text:
        await page.keyboard.type(char)
        await asyncio.sleep(random.uniform(0.05, 0.15))

async def human_scroll(page, direction="down", amount=None):
    amount = amount or random.randint(200, 500)
    steps = random.randint(3, 8)
    for _ in range(steps):
        delta = amount // steps + random.randint(-20, 20)
        await page.mouse.wheel(0, delta if direction == "down" else -delta)
        await asyncio.sleep(random.uniform(0.1, 0.4))
```

---

## 5. 22-Day Account Warming Protocol

```python
WARMING_SCHEDULE = {
    # Day: (actions_per_day, action_types, session_duration_minutes)
    1:  (3,  ["browse_feed"],                    5),
    2:  (5,  ["browse_feed", "watch_video"],     8),
    3:  (5,  ["browse_feed", "watch_video"],    10),
    4:  (8,  ["browse", "watch", "like"],       12),
    5:  (10, ["browse", "watch", "like"],       15),
    7:  (12, ["browse", "watch", "like", "comment_short"], 20),
    10: (15, ["browse", "watch", "like", "comment", "subscribe"], 25),
    14: (20, ["all_actions"], 30),
    18: (25, ["all_actions", "upload_test"], 35),
    22: (30, ["full_operations"], 45),
}

async def warming_session(account, day):
    schedule = WARMING_SCHEDULE.get(day, WARMING_SCHEDULE[22])
    actions, types, duration = schedule

    async with create_browser(account) as page:
        start = time.time()
        for i in range(actions):
            action = random.choice(types)
            await execute_action(page, action)
            # Random delay between actions
            await asyncio.sleep(random.uniform(30, 120))
            # Check if session duration exceeded
            if (time.time() - start) > duration * 60:
                break
```

---

## 6. Proxy Rotation

```python
PROXY_POOLS = {
    "youtube": [
        {"server": "us-residential-1.proxy.com:8080", "geo": "US"},
        {"server": "us-residential-2.proxy.com:8080", "geo": "US"},
    ],
    "tiktok": [
        {"server": "sg-residential-1.proxy.com:8080", "geo": "SG"},
    ],
}

def get_proxy_for_account(account):
    """Consistent proxy per account — never change mid-session"""
    pool = PROXY_POOLS[account.platform]
    # Hash account ID to consistently pick same proxy
    idx = hash(account.id) % len(pool)
    return pool[idx]
```

---

## 7. CAPTCHA Handling

```python
async def handle_captcha(page, app_handle):
    captcha = await page.query_selector('[class*="captcha"], [id*="captcha"]')
    if captcha:
        # Pause automation
        await app_handle.emit("browser:captcha_detected", {
            "account": account.id,
            "platform": account.platform,
            "screenshot": await page.screenshot(),
        })
        # Wait for user to solve manually
        await app_handle.wait_for_event("browser:captcha_solved", timeout=300)
        # Resume
```

---

## 8. Fallback Selector Strategy

```python
SELECTORS = {
    "youtube_like_button": [
        # Primary — most reliable
        'button[aria-label*="like this video"]',
        # Fallback 1 — class-based
        '#segmented-like-button button',
        # Fallback 2 — structural
        'ytd-menu-renderer yt-button-shape:first-child button',
        # Fallback 3 — text content
        'button:has(path[d*="M3.5"])', # SVG path of thumbs-up
    ],
}

async def click_with_fallback(page, selector_key):
    for selector in SELECTORS[selector_key]:
        try:
            element = await page.wait_for_selector(selector, timeout=3000)
            if element:
                await human_click(page, selector)
                return True
        except:
            continue
    raise AppError("E3003", f"All selectors failed for {selector_key}")
```

---

## 9. Account Health Monitoring

```python
HEALTH_THRESHOLDS = {
    "daily_action_limit": 50,
    "hourly_action_limit": 10,
    "min_session_gap_hours": 2,
    "max_failed_actions": 3,
    "account_age_days_for_full": 22,
}

def calculate_health_score(account) -> float:
    """0.0 (critical) to 1.0 (healthy)"""
    score = 1.0
    if account.failed_actions_today > 3: score -= 0.3
    if account.actions_today > 40: score -= 0.2
    if account.captcha_count_week > 2: score -= 0.3
    if account.age_days < 22: score *= (account.age_days / 22)
    return max(0.0, min(1.0, score))
```

---

## 10. Best Practices

1. **One proxy per account** — never rotate proxy for same account
2. **Virtual headless, not true headless** — `headless="virtual"` evades detection
3. **Session persistence** — maintain cookies/localStorage between runs
4. **Random delays** — 30-120s between actions, human variance
5. **Warming before farming** — 22-day gradual activity increase
6. **Health monitoring** — pause accounts with score < 0.3
7. **CAPTCHA = pause** — never auto-solve, notify user
8. **Fallback selectors** — 3-4 alternative paths per UI element
9. **Rate limit per platform** — respect platform-specific limits
10. **Logs everything** — action type, timestamp, result, error for debugging
