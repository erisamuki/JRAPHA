-- Extend an existing installation to support dedicated cashier accounts,
-- bank-card payments, and an auditable record for each payment.
ALTER TYPE user_role ADD VALUE IF NOT EXISTS 'cashier';
ALTER TYPE payment_method ADD VALUE IF NOT EXISTS 'bank_card';

CREATE TABLE IF NOT EXISTS billing_payments (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    billing_id      UUID NOT NULL REFERENCES billing(id) ON DELETE CASCADE,
    amount_ugx      NUMERIC(12,2) NOT NULL CHECK (amount_ugx > 0),
    payment_method  payment_method NOT NULL,
    reference       VARCHAR(100),
    processed_by    UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_billing_payments_billing
    ON billing_payments(billing_id, created_at);

-- Preserve the existing paid total as a starting history entry. Subsequent
-- payments are recorded individually by the cashier endpoint.
INSERT INTO billing_payments (billing_id, amount_ugx, payment_method, processed_by, created_at)
SELECT b.id, b.amount_paid_ugx, COALESCE(b.payment_method, 'other'), b.processed_by, b.updated_at
FROM billing b
WHERE b.amount_paid_ugx > 0
  AND NOT EXISTS (
      SELECT 1 FROM billing_payments bp WHERE bp.billing_id = b.id
  );
