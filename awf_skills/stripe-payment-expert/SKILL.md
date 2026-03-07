---
name: stripe-payment-expert
description: Payment integration patterns — Stripe Checkout, subscriptions, webhooks, credit systems, SePay VN bank transfer, NOWPayments crypto, invoice generation, and PCI compliance. For desktop + web hybrid billing.
---

# Stripe Payment Expert — Billing & Monetization

Use this skill for implementing payment, subscription, and credit systems.

---

## 1. Stripe Checkout Session

### Create Checkout (Rust Backend → Stripe API)
```rust
use reqwest::Client;

pub async fn create_checkout_session(
    plan: &str,
    customer_email: &str,
) -> Result<CheckoutUrl, AppError> {
    let client = Client::new();
    let resp = client.post("https://api.stripe.com/v1/checkout/sessions")
        .bearer_auth(&std::env::var("STRIPE_SECRET_KEY")?)
        .form(&[
            ("mode", "subscription"),
            ("customer_email", customer_email),
            ("line_items[0][price]", get_price_id(plan)),
            ("line_items[0][quantity]", "1"),
            ("success_url", "metagen://payment/success?session_id={CHECKOUT_SESSION_ID}"),
            ("cancel_url", "metagen://payment/cancel"),
            ("allow_promotion_codes", "true"),
            ("billing_address_collection", "auto"),
        ])
        .send().await?
        .json::<serde_json::Value>().await?;

    Ok(CheckoutUrl {
        url: resp["url"].as_str().unwrap().to_string(),
        session_id: resp["id"].as_str().unwrap().to_string(),
    })
}

fn get_price_id(plan: &str) -> &'static str {
    match plan {
        "starter" => "price_starter_monthly_id",
        "pro" => "price_pro_monthly_id",
        "business" => "price_business_monthly_id",
        _ => "price_starter_monthly_id",
    }
}
```

---

## 2. Webhook Handler (Supabase Edge Function)

```typescript
import Stripe from 'stripe';
const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY')!);

Deno.serve(async (req) => {
  const body = await req.text();
  const sig = req.headers.get('stripe-signature')!;

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(
      body, sig, Deno.env.get('STRIPE_WEBHOOK_SECRET')!
    );
  } catch (err) {
    return new Response('Webhook signature verification failed', { status: 400 });
  }

  switch (event.type) {
    case 'checkout.session.completed': {
      const session = event.data.object as Stripe.Checkout.Session;
      await activateSubscription(session.customer_email!, session.subscription as string);
      break;
    }
    case 'invoice.payment_succeeded': {
      const invoice = event.data.object as Stripe.Invoice;
      await renewCredits(invoice.customer as string, invoice.lines.data[0].price!.id);
      break;
    }
    case 'customer.subscription.deleted': {
      const sub = event.data.object as Stripe.Subscription;
      await deactivateSubscription(sub.customer as string);
      break;
    }
    case 'invoice.payment_failed': {
      const invoice = event.data.object as Stripe.Invoice;
      await handlePaymentFailed(invoice.customer as string, invoice.attempt_count!);
      break;
    }
  }

  return new Response(JSON.stringify({ received: true }), { status: 200 });
});
```

---

## 3. Credit System

### Database Schema
```sql
CREATE TABLE credit_transactions (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id),
    amount INTEGER NOT NULL,  -- positive = add, negative = consume
    type TEXT NOT NULL CHECK(type IN ('purchase','consume','refund','expire','bonus')),
    description TEXT,
    reference_id TEXT,  -- video_id, payment_id, etc.
    balance_after INTEGER NOT NULL,
    created_at TEXT DEFAULT (datetime('now'))
);

CREATE INDEX idx_credits_user ON credit_transactions(user_id, created_at DESC);
```

### Credit Operations (Rust)
```rust
pub async fn consume_credits(
    db: &DbPool,
    user_id: &str,
    amount: u32,
    description: &str,
    reference_id: &str,
) -> Result<u32, AppError> {
    let balance = db.get_balance(user_id)?;
    if balance < amount {
        return Err(AppError::new("E7003", format!(
            "Insufficient credits: have {balance}, need {amount}"
        )));
    }
    let new_balance = balance - amount;
    db.insert_transaction(CreditTransaction {
        user_id: user_id.into(),
        amount: -(amount as i32),
        tx_type: "consume".into(),
        description: description.into(),
        reference_id: reference_id.into(),
        balance_after: new_balance,
    })?;
    Ok(new_balance)
}
```

---

## 4. Plan Tiers

```rust
pub enum Plan {
    Free,
    Starter,  // $19/mo
    Pro,      // $49/mo
    Business, // $99/mo
}

impl Plan {
    pub fn monthly_credits(&self) -> u32 {
        match self {
            Self::Free => 10,
            Self::Starter => 100,
            Self::Pro => 500,
            Self::Business => 2000,
        }
    }

    pub fn features(&self) -> Vec<&str> {
        match self {
            Self::Free => vec!["basic_video", "3_ai_keys"],
            Self::Starter => vec!["hd_video", "10_ai_keys", "captions", "batch_5"],
            Self::Pro => vec!["4k_video", "unlimited_keys", "all_features", "batch_50"],
            Self::Business => vec!["4k_video", "unlimited_keys", "all_features", "batch_unlimited", "api_access", "white_label"],
        }
    }
}
```

---

## 5. SePay VN Bank Transfer

```rust
pub async fn create_sepay_order(
    amount_vnd: u32,
    user_id: &str,
) -> Result<SepayOrder, AppError> {
    let order_code = format!("MG{}", generate_short_id());
    let client = Client::new();
    let resp = client.post("https://my.sepay.vn/userapi/transactions/create")
        .header("Authorization", format!("Bearer {}", env::var("SEPAY_API_KEY")?))
        .json(&serde_json::json!({
            "amount": amount_vnd,
            "description": format!("MetaGen {order_code}"),
            "order_code": order_code,
            "callback_url": env::var("SEPAY_CALLBACK_URL")?,
        }))
        .send().await?.json::<serde_json::Value>().await?;

    Ok(SepayOrder {
        order_code,
        qr_url: resp["data"]["qr_url"].as_str().unwrap().to_string(),
        bank_account: resp["data"]["bank_account"].as_str().unwrap().to_string(),
        amount: amount_vnd,
    })
}
```

---

## 6. NOWPayments Crypto

```rust
pub async fn create_crypto_invoice(
    amount_usd: f64,
    user_id: &str,
) -> Result<CryptoInvoice, AppError> {
    let client = Client::new();
    let resp = client.post("https://api.nowpayments.io/v1/invoice")
        .header("x-api-key", env::var("NOWPAY_API_KEY")?)
        .json(&serde_json::json!({
            "price_amount": amount_usd,
            "price_currency": "usd",
            "pay_currency": "usdttrc20",
            "order_id": format!("mg-{user_id}-{}", chrono::Utc::now().timestamp()),
            "ipn_callback_url": env::var("NOWPAY_IPN_URL")?,
        }))
        .send().await?.json::<serde_json::Value>().await?;

    Ok(CryptoInvoice {
        invoice_url: resp["invoice_url"].as_str().unwrap().to_string(),
        pay_address: resp["pay_address"].as_str().map(String::from),
    })
}
```

---

## 7. Best Practices

1. **Webhook idempotency** — check `event.id` to prevent duplicate processing
2. **Verify signatures** — always validate Stripe webhook signatures
3. **Credit ledger** — immutable transaction log, never update balance directly
4. **Grace period** — 3-day grace on payment failure before deactivation
5. **Deep link success** — `metagen://payment/success` for desktop app callback
6. **PCI Level 4** — client-side tokenization only, no card data on server
7. **Multiple payment methods** — Stripe + SePay + Crypto covers global users
8. **Proration on plan change** — Stripe handles automatically with `proration_behavior`
9. **Credit expiry** — monthly credits expire at end of billing cycle
10. **Refund via credits** — issue credit refund, not payment refund for in-app purchases
